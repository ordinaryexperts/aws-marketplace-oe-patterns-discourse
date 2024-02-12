import os
import subprocess

from aws_cdk import (
    CfnMapping,
    CfnOutput,
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
from oe_patterns_cdk_common.efs import Efs
from oe_patterns_cdk_common.elasticache_cluster import ElasticacheRedis
from oe_patterns_cdk_common.ses import Ses
from oe_patterns_cdk_common.util import Util
from oe_patterns_cdk_common.vpc import Vpc

if 'TEMPLATE_VERSION' in os.environ:
    template_version = os.environ['TEMPLATE_VERSION']
else:
    try:
        template_version = subprocess.check_output(["git", "describe", "--always"]).strip().decode('ascii')
    except:
        template_version = "CICD"

AMI_ID="ami-01c4f3d5ecf8fbb3c"
AMI_NAME="ordinary-experts-patterns-discourse-07e8d10-20231221-0621"
generated_ami_ids = {
    "us-east-1": "ami-01c4f3d5ecf8fbb3c"
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

        self.admin_emails_param = CfnParameter(
            self,
            "AdminEmails",
            default="",
            description="Comma-separated list of admin emails for this Discourse site."
        )

        self.plugin_commands_list_param = CfnParameter(
            self,
            "PluginCommandsList",
            default="",
            description="Comma-separated list of commands to run to install plugins."
        )

        dns = Dns(self, "Dns")

        bucket = AssetsBucket(
            self,
            "AssetsBucket",
            object_ownership_value = "ObjectWriter",
            remove_public_access_block = True
        )

        # redis
        redis = ElasticacheRedis(
            self,
            "Redis",
            vpc=vpc
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

        with open("discourse/user_data.sh") as f:
            user_data = f.read()
        asg = Asg(
            self,
            "Asg",
            secret_arns=[db_secret.secret_arn(), ses.secret_arn()],
            create_and_update_timeout_minutes = 30,
            default_instance_type = "t3.xlarge",
            use_graviton = False,
            user_data_contents = user_data,
            user_data_variables = {
                "AssetsBucketName": bucket.bucket_name(),
                "DbSecretArn": db_secret.secret_arn(),
                "HostedZoneName": dns.route_53_hosted_zone_name_param.value_as_string,
                "Hostname": dns.hostname(),
                "InstanceSecretArn": ses.secret_arn(),
                "PluginCommandsList": self.plugin_commands_list_param.value_as_string
            },
            vpc = vpc
        )
        asg.asg.node.add_dependency(db.db_primary_instance)
        Util.add_sg_ingress(db, asg.sg)
        Util.add_sg_ingress(redis, asg.sg)

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

        # efs
        efs = Efs(self, "Efs", app_sg=asg.sg, vpc=vpc)

        alb = Alb(
            self,
            "Alb",
            asg=asg,
            health_check_path="/srv/status",
            vpc=vpc
        )
        asg.asg.target_group_arns = [ alb.target_group.ref ]

        dns.add_alb(alb)

        CfnOutput(
            self,
            "FirstUseInstructions",
            description="Instructions for getting started",
            value="Click on the DnsSiteUrlOutput link and register a new user using one of the emails specified in the 'Admin Emails' parameter. You should then receive a confirmation email to complete the registration as an admin user."
        )

        parameter_groups = [
            {
                "Label": {
                    "default": "Application Config"
                },
                "Parameters": [
                    self.name_param.logical_id,
                    self.admin_emails_param.logical_id,
                    self.plugin_commands_list_param.logical_id
                ]
            }
        ]
        parameter_groups += alb.metadata_parameter_group()
        parameter_groups += bucket.metadata_parameter_group()
        parameter_groups += db_secret.metadata_parameter_group()
        parameter_groups += db.metadata_parameter_group()
        parameter_groups += dns.metadata_parameter_group()
        parameter_groups += efs.metadata_parameter_group()
        parameter_groups += redis.metadata_parameter_group()
        parameter_groups += asg.metadata_parameter_group()
        parameter_groups += ses.metadata_parameter_group()
        parameter_groups += vpc.metadata_parameter_group()

        # AWS::CloudFormation::Interface
        self.template_options.metadata = {
            "OE::Patterns::TemplateVersion": template_version,
            "AWS::CloudFormation::Interface": {
                "ParameterGroups": parameter_groups,
                "ParameterLabels": {
                    self.name_param.logical_id: {
                        "default": "Discourse Site Name"
                    },
                    self.admin_emails_param.logical_id: {
                        "default": "Admin Emails"
                    },
                    self.plugin_commands_list_param.logical_id: {
                        "default": "Plugin Commands List"
                    },
                    **alb.metadata_parameter_labels(),
                    **bucket.metadata_parameter_labels(),
                    **db_secret.metadata_parameter_labels(),
                    **db.metadata_parameter_labels(),
                    **dns.metadata_parameter_labels(),
                    **efs.metadata_parameter_labels(),
                    **redis.metadata_parameter_labels(),
                    **asg.metadata_parameter_labels(),
                    **ses.metadata_parameter_labels(),
                    **vpc.metadata_parameter_labels()
                }
            }
        }
