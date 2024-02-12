SCRIPT_VERSION=1.3.0
SCRIPT_PREINSTALL=ubuntu_2004_2204_preinstall.sh
SCRIPT_POSTINSTALL=ubuntu_2004_2204_postinstall.sh

# preinstall steps
curl -O "https://raw.githubusercontent.com/ordinaryexperts/aws-marketplace-utilities/$SCRIPT_VERSION/packer_provisioning_scripts/$SCRIPT_PREINSTALL"
chmod +x $SCRIPT_PREINSTALL
./$SCRIPT_PREINSTALL --install-efs-utils
rm $SCRIPT_PREINSTALL

# aws cloudwatch
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root",
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "metrics": {
    "metrics_collected": {
      "collectd": {
        "metrics_aggregation_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    },
    "append_dimensions": {
      "ImageId": "\${aws:ImageId}",
      "InstanceId": "\${aws:InstanceId}",
      "InstanceType": "\${aws:InstanceType}",
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}"
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/dpkg.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/dpkg.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/apt/history.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/apt/history.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/cloud-init.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/cloud-init-output.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/auth.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/syslog",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/amazon/ssm/amazon-ssm-agent.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/amazon/ssm/amazon-ssm-agent.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/amazon/ssm/errors.log",
            "log_group_name": "ASG_SYSTEM_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/log/amazon/ssm/errors.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/nginx/access.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/nginx/access.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/nginx/error.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/nginx/error.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/kern.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/kern.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/user.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/user.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/messages",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/messages",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/syslog",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/syslog",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/auth.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/auth.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/rails/sidekiq.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/rails/sidekiq.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/rails/production_errors.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/rails/production_errors.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/rails/unicorn.stderr.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/rails/unicorn.stderr.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/rails/unicorn.stdout.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/rails/unicorn.stdout.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/discourse/shared/standalone/log/var-log/rails/production.log",
            "log_group_name": "ASG_APP_LOG_GROUP_PLACEHOLDER",
            "log_stream_name": "{instance_id}-/var/discourse/shared/standalone/log/var-log/rails/production.log",
            "timezone": "UTC"
          }
        ]
      }
    },
    "log_stream_name": "{instance_id}"
  }
}
EOF

# Install Docker
apt-get update
apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md#5-install-discourse
git clone https://github.com/discourse/discourse_docker.git /var/discourse
cd /var/discourse
git checkout fcce1376043adeb09e21ec1ec079a41e4d29fe6e # base image to discourse/base:2.0.20231218-0429
chmod 700 containers
# fix ELB health check
sed -i '48,50c\
       set $should_redirect "no"; \
       if ($http_host != $$ENV_DISCOURSE_HOSTNAME) { \
          set $should_redirect "yes"; \
       } \
       if ($request_uri = "/srv/status") { \
          set $should_redirect "no"; \
       } \
       if ($should_redirect = "yes") { \
          rewrite (.*) https://$$ENV_DISCOURSE_HOSTNAME$1 permanent; \
       }
' /var/discourse/templates/web.ssl.template.yml
# pull initial image
docker pull discourse/base:2.0.20231218-0429

# post install steps
curl -O "https://raw.githubusercontent.com/ordinaryexperts/aws-marketplace-utilities/$SCRIPT_VERSION/packer_provisioning_scripts/$SCRIPT_POSTINSTALL"
chmod +x "$SCRIPT_POSTINSTALL"
./"$SCRIPT_POSTINSTALL"
rm $SCRIPT_POSTINSTALL
