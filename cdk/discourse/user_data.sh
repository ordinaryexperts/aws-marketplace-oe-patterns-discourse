#!/bin/bash

# aws cloudwatch
sed -i 's/ASG_APP_LOG_GROUP_PLACEHOLDER/${AsgAppLogGroup}/g' /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sed -i 's/ASG_SYSTEM_LOG_GROUP_PLACEHOLDER/${AsgSystemLogGroup}/g' /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# reprovision if access key is rotated
# access key serial: ${SesInstanceUserAccessKeySerial}

mkdir -p /opt/oe/patterns

# efs
mkdir /mnt/efs
echo "${AppEfs}:/ /mnt/efs efs _netdev 0 0" >> /etc/fstab
mount -a
mkdir -p /mnt/efs/discourse/shared
if [ -d /var/discourse/shared ] && [ ! -L /var/discourse/shared ]; then
    rm -rf /var/discourse/shared
    ln -s /mnt/efs/discourse/shared /var/discourse
    mkdir -p /var/discourse/shared/standalone/ssl

    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout /var/discourse/shared/standalone/ssl/ssl.key \
            -out /var/discourse/shared/standalone/ssl/ssl.crt \
            -subj '/CN=localhost'
fi

# DB secret
DB_SECRET_ARN="${DbSecretArn}"
echo $DB_SECRET_ARN > /opt/oe/patterns/db-secret-arn.txt

aws secretsmanager get-secret-value \
    --secret-id "$DB_SECRET_ARN" \
    --query SecretString \
| jq -r > /opt/oe/patterns/db-secret.json

export DB_PASSWORD=$(cat /opt/oe/patterns/db-secret.json | jq -r .password)
export DB_USERNAME=$(cat /opt/oe/patterns/db-secret.json | jq -r .username)

# Instance secret
INSTANCE_SECRET_ARN="${InstanceSecretArn}"
echo $INSTANCE_SECRET_ARN > /opt/oe/patterns/instance-secret-arn.txt

aws secretsmanager get-secret-value \
    --secret-id "$INSTANCE_SECRET_ARN" \
    --query SecretString \
| jq -r > /opt/oe/patterns/instance-secret.json

export DISCOURSE_SMTP_ADDRESS="email-smtp.${AWS::Region}.amazonaws.com"
export DISCOURSE_SMTP_USER_NAME=$(cat /opt/oe/patterns/instance-secret.json | jq -r .access_key_id)
export DISCOURSE_SMTP_PASSWORD=$(cat /opt/oe/patterns/instance-secret.json | jq -r .smtp_password)
export ACCESS_KEY_ID=$(cat /opt/oe/patterns/instance-secret.json | jq -r .access_key_id)
export SECRET_ACCESS_KEY=$(cat /opt/oe/patterns/instance-secret.json | jq -r .secret_access_key)

cat <<EOF > /var/discourse/containers/app.yml
templates:
  - "templates/web.template.yml"
  - "templates/web.ratelimited.template.yml"
  - "templates/web.ssl.template.yml"

expose:
  - "443:443" # https

params:
  db_default_text_search_config: "pg_catalog.english"

  ## Set db_shared_buffers to a max of 25% of the total memory.
  ## will be set automatically by bootstrap based on detected RAM, or you can override
  #db_shared_buffers: "4096MB"

  ## can improve sorting performance, but adds memory usage per-connection
  #db_work_mem: "40MB"

  ## Which Git revision should this container use? (default: tests-passed)
  version: v3.4.2

env:
  LC_ALL: en_US.UTF-8
  LANG: en_US.UTF-8
  LANGUAGE: en_US.UTF-8
  # DISCOURSE_DEFAULT_LOCALE: en

  # DB Settings
  DISCOURSE_DB_USERNAME: $DB_USERNAME
  DISCOURSE_DB_PASSWORD: $DB_PASSWORD
  DISCOURSE_DB_HOST: ${DbCluster.Endpoint.Address}
  DISCOURSE_DB_NAME: discourse

  DISCOURSE_USE_S3: true
  DISCOURSE_S3_REGION: ${AWS::Region}
  DISCOURSE_S3_ACCESS_KEY_ID: $ACCESS_KEY_ID
  DISCOURSE_S3_SECRET_ACCESS_KEY: $SECRET_ACCESS_KEY
  DISCOURSE_S3_CDN_URL: https://${AssetsBucketName}.s3.${AWS::Region}.amazonaws.com
  DISCOURSE_S3_BUCKET: ${AssetsBucketName}
  DISCOURSE_S3_BACKUP_BUCKET: ${AssetsBucketName}/backups
  DISCOURSE_BACKUP_LOCATION: s3

  ## How many concurrent web requests are supported? Depends on memory and CPU cores.
  ## will be set automatically by bootstrap based on detected CPUs, or you can override
  #UNICORN_WORKERS: 4

  DISCOURSE_HOSTNAME: ${Hostname}

  ## Uncomment if you want the container to be started with the same
  ## hostname (-h option) as specified above (default "$hostname-$config")
  #DOCKER_USE_HOSTNAME: true

  ## List of comma delimited emails that will be made admin and developer
  ## on initial signup example 'user1@example.com,user2@example.com'
  DISCOURSE_DEVELOPER_EMAILS: '${AdminEmails}'

  DISCOURSE_SMTP_ADDRESS: $DISCOURSE_SMTP_ADDRESS
  DISCOURSE_SMTP_PORT: 587
  DISCOURSE_SMTP_USER_NAME: $DISCOURSE_SMTP_USER_NAME
  DISCOURSE_SMTP_PASSWORD: "$DISCOURSE_SMTP_PASSWORD"
  #DISCOURSE_SMTP_ENABLE_START_TLS: true           # (optional, default true)
  DISCOURSE_SMTP_DOMAIN: ${HostedZoneName}
  DISCOURSE_NOTIFICATION_EMAIL: no-reply@${HostedZoneName}

  DISCOURSE_REDIS_HOST: ${RedisCluster.RedisEndpoint.Address}

  ## The http or https CDN address for this Discourse instance (configured to pull)
  ## see https://meta.discourse.org/t/14857 for details
  #DISCOURSE_CDN_URL: https://discourse-cdn.example.com

  ## The maxmind geolocation IP address key for IP address lookup
  ## see https://meta.discourse.org/t/-/137387/23 for details
  #DISCOURSE_MAXMIND_LICENSE_KEY: 1234567890123456

## The Docker container is stateless; all data is stored in /shared
volumes:
  - volume:
      host: /var/discourse/shared/standalone
      guest: /shared
  - volume:
      host: /var/discourse/shared/standalone/log/var-log
      guest: /var/log

## Plugins go here
## see https://meta.discourse.org/t/19157 for details
hooks:
  after_assets_precompile:
    - exec:
        cd: \$home
        cmd:
          - sudo -E -u discourse bundle exec rake s3:upload_assets
          - sudo -E -u discourse bundle exec rake s3:expire_missing_assets
  after_code:
    - exec:
        cd: \$home/plugins
        cmd:
          - git clone https://github.com/discourse/docker_manager.git

## Any custom commands to run after building
run:
  - exec: echo "Beginning of custom commands"
  ## If you want to set the 'From' email address for your first registration, uncomment and change:
  ## After getting the first signup email, re-comment the line. It only needs to run once.
  #- exec: rails r "SiteSetting.notification_email='info@unconfigured.discourse.org'"
  - exec: rails r "SiteSetting.force_https=true"
  - exec: echo "End of custom commands"
EOF
chmod o-rwx /var/discourse/containers/app.yml

PLUGIN_COMMANDS_LIST="${PluginCommandsList}"
if [ -n "$PLUGIN_COMMANDS_LIST" ]; then
    cd /var/discourse/containers
    awk -v list="$PLUGIN_COMMANDS_LIST" '/- git clone https:\/\/github.com\/discourse\/docker_manager.git/ {
        print
        n = split(list, arr, ",")
        for (i = 1; i <= n; i++) {
            printf "          - %s\n", arr[i]
        }
        next
    }1' app.yml > temp.yml && mv temp.yml app.yml
fi
cd /var/discourse
existing=`docker ps -a | awk '{ print $1, $(NF) }' | grep " app$" | awk '{ print $1 }'`
if [ ! -z $existing ]; then
    echo "Stopping old container"
    (
        set -x
        docker stop -t 600 app
    )
fi
./launcher bootstrap app
if [ ! -z $existing ]; then
    echo "Removing old container"
    (
        set -x
        docker rm app
    )
fi
./launcher start app

success=$?
cfn-signal --exit-code $success --stack ${AWS::StackName} --resource Asg --region ${AWS::Region}
