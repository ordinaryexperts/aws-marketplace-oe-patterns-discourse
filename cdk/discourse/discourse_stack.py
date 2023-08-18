from aws_cdk import (
    Aws,
    CfnMapping,
    CfnParameter,
    aws_secretsmanager,
    Stack
)

from constructs import Construct

from oe_patterns_cdk_common.alb import Alb
from oe_patterns_cdk_common.asg import Asg
from oe_patterns_cdk_common.assets_bucket import AssetsBucket
from oe_patterns_cdk_common.aurora_cluster import AuroraPostgresql
from oe_patterns_cdk_common.db_secret import DbSecret
from oe_patterns_cdk_common.dns import Dns
from oe_patterns_cdk_common.ses import Ses
from oe_patterns_cdk_common.util import Util
from oe_patterns_cdk_common.vpc import Vpc

AMI_ID="ami-073d4397976bc560c"
AMI_NAME="ordinary-experts-patterns-discourse--20230323-0624"
generated_ami_ids = {
    "us-east-1": "ami-073d4397976bc560c"
}
# End generated code block.

class DiscourseStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # vpc
        vpc = Vpc(
            self,
            "Vpc"
        )

        self.name_param = CfnParameter(
            self,
            "Name",
            default="Discourse",
            description="The name of this Discourse site."
        )

        dns = Dns(self, "Dns")

        bucket = AssetsBucket(
            self,
            "AssetsBucket"
        )

        ses = Ses(
            self,
            "Ses",
            hosted_zone_name=dns.route_53_hosted_zone_name_param.value_as_string,
            additional_iam_user_policies=[bucket.user_policy]
        )

        db_secret = DbSecret(
            self,
            "DbSecret",
            username = "discourse"
        )

        db = AuroraPostgresql(
            self,
            "Db",
            database_name="discourse",
            db_secret=db_secret,
            vpc=vpc
        )

        #instanceSecret = aws_secretsmanager.Secret.fromSecretName(self, 'InstanceSecret', Aws.STACK_NAME + "/instance/credentials");
        instanceSecretArn = "arn:aws:secretsmanager:us-east-1:992593896645:secret:oe-patterns-discourse-richardgavel/instance/credentials-nvx4tZ"

        with open("discourse/user_data.sh") as f:
            user_data = f.read()
        asg = Asg(
            self,
            "Asg",
            secret_arns=[db_secret.secret_arn(), ses.secret_arn()],
            default_instance_type = "t3.xlarge",
            use_graviton = False,
            user_data_contents = user_data,
            user_data_variables = {
                "AssetsBucketName": bucket.bucket_name(),
                "DbSecretArn": db_secret.secret_arn(),
                "Hostname": dns.hostname(),
                "HostedZoneName": dns.route_53_hosted_zone_name_param.value_as_string,
                "InstanceSecretArn": ses.secret_arn()
            },
            vpc = vpc
        )
        asg.asg.node.add_dependency(db.db_primary_instance)
        Util.add_sg_ingress(db, asg.sg)

        ami_mapping={
            "AMI": {
                "OECONSUL": AMI_NAME
            }
        }
        for region in generated_ami_ids.keys():
            ami_mapping[region] = { "AMI": generated_ami_ids[region] }
        CfnMapping(
            self,
            "AWSAMIRegionMap",
            mapping=ami_mapping
        )

        alb = Alb(self, "Alb", asg=asg, vpc=vpc)
        asg.asg.target_group_arns = [ alb.target_group.ref ]

        dns.add_alb(alb)
