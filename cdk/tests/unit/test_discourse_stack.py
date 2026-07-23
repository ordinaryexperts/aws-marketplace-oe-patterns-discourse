import aws_cdk as core
import aws_cdk.assertions as assertions

from discourse.discourse_stack import DiscourseStack


def _launch_template_resource():
    app = core.App()
    stack = DiscourseStack(app, "discourse")
    template = assertions.Template.from_stack(stack)
    launch_templates = template.find_resources("AWS::EC2::LaunchTemplate")
    assert len(launch_templates) == 1
    return next(iter(launch_templates.values()))


def _launch_template_user_data_sub():
    launch_template = _launch_template_resource()
    return launch_template["Properties"]["LaunchTemplateData"]["UserData"]["Fn::Base64"]["Fn::Sub"]


def test_user_data_wires_discourse_db_host_from_aurora_cluster():
    user_data, sub_vars = _launch_template_user_data_sub()

    assert "DISCOURSE_DB_HOST: ${DbHost}" in user_data

    db_host = sub_vars.get("DbHost")
    assert db_host is not None, "DbHost must be a real Fn::Sub variable, not missing/blank"
    assert db_host["Fn::GetAtt"][1] == "Endpoint.Address"


def test_user_data_wires_discourse_redis_host_from_elasticache_cluster():
    user_data, sub_vars = _launch_template_user_data_sub()

    assert "DISCOURSE_REDIS_HOST: ${RedisHost}" in user_data

    redis_host = sub_vars.get("RedisHost")
    assert redis_host is not None, "RedisHost must be a real Fn::Sub variable, not missing/blank"
    assert redis_host["Fn::GetAtt"][1] == "RedisEndpoint.Address"


def test_launch_template_depends_on_db_and_redis_completing_first():
    launch_template = _launch_template_resource()

    depends_on = launch_template.get("DependsOn", [])
    if isinstance(depends_on, str):
        depends_on = [depends_on]

    assert "DbPrimaryInstance" in depends_on, (
        "AsgLaunchTemplate must explicitly DependsOn DbPrimaryInstance, or CloudFormation "
        "can create the launch template (baking in UserData) before the DB is ready, "
        "relying only on implicit Fn::Sub/GetAtt dependency inference which is not reliable"
    )
    assert "RedisCluster" in depends_on, (
        "AsgLaunchTemplate must explicitly DependsOn RedisCluster, or CloudFormation "
        "can create the launch template (baking in UserData) before Redis is ready, "
        "relying only on implicit Fn::Sub/GetAtt dependency inference which is not reliable"
    )
