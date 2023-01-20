from aws_cdk import (
    Aws,
    CfnMapping,
    CfnParameter,
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

# AMI_ID="ami-01be9e4e694f60ba2"
# AMI_NAME="ordinary-experts-patterns-discourse--20221218-0306"
# generated_ami_ids = {
#     "us-east-1": "ami-01be9e4e694f60ba2"
# }
# End generated code block.
AMI_ID="ami-01be9e4e694f60ba2"
AMI_NAME="ordinary-experts-patterns-discourse--20221218-0306"
generated_ami_ids = {
    "us-east-1": "ami-01be9e4e694f60ba2"
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

        Ses(
            self,
            "Ses",
            hosted_zone_name=dns.route_53_hosted_zone_name_param.value_as_string,
            additional_iam_user_policies=[bucket.user_policy]
        )

        db_secret = DbSecret(
            self,
            "DbSecret"
        )

        db = AuroraPostgresql(
            self,
            "Db",
            db_secret=db_secret,
            vpc=vpc
        )

        with open("discourse/launch_config_user_data.sh") as f:
            launch_config_user_data = f.read()
        asg = Asg(
            self,
            "Asg",
            secret_arns=[db_secret.secret_arn()],
            default_instance_type = "t3.xlarge",
            user_data_contents = launch_config_user_data,
            user_data_variables = {
                "AssetsBucketName": bucket.bucket_name(),
                "DbSecretArn": db_secret.secret_arn(),
                "Hostname": dns.hostname(),
                "HostedZoneName": dns.route_53_hosted_zone_name_param.value_as_string,
                "InstanceSecretName": Aws.STACK_NAME + "/instance/credentials"
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

        alb = Alb(self, "Alb", asg=asg, vpc=vpc, target_group_https = False)
        asg.asg.target_group_arns = [ alb.target_group.ref ]

        dns.add_alb(alb)
