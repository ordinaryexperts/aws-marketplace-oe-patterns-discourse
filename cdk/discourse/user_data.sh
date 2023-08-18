#!/bin/bash

mkdir -p /opt/oe/patterns

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

cat <<EOF > /var/discourse/containers/app.yml
## this is the all-in-one, standalone Discourse Docker container template
##
## After making changes to this file, you MUST rebuild
## /var/discourse/launcher rebuild app
##
## BE *VERY* CAREFUL WHEN EDITING!
## YAML FILES ARE SUPER SUPER SENSITIVE TO MISTAKES IN WHITESPACE OR ALIGNMENT!
## visit http://www.yamllint.com/ to validate this file as needed

templates:
  - "templates/redis.template.yml"
  - "templates/web.template.yml"
  - "templates/web.ratelimited.template.yml"
##   - "templates/postgres.template.yml"
## Uncomment these two lines if you wish to add Lets Encrypt (https)
  - "templates/web.ssl.template.yml"
  - "templates/web.letsencrypt.ssl.template.yml"

## which TCP/IP ports should this container expose?
## If you want Discourse to share a port with another webserver like Apache or nginx,
## see https://meta.discourse.org/t/17247 for details
expose:
  - "80:80"   # http
  - "443:443" # https

params:
  db_default_text_search_config: "pg_catalog.english"

  ## Set db_shared_buffers to a max of 25% of the total memory.
  ## will be set automatically by bootstrap based on detected RAM, or you can override
  db_shared_buffers: "4096MB"

  ## can improve sorting performance, but adds memory usage per-connection
  #db_work_mem: "40MB"

  ## Which Git revision should this container use? (default: tests-passed)
  #version: tests-passed

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

  ## How many concurrent web requests are supported? Depends on memory and CPU cores.
  ## will be set automatically by bootstrap based on detected CPUs, or you can override
  UNICORN_WORKERS: 4

  ## TODO: The domain name this Discourse instance will respond to
  ## Required. Discourse will not work with a bare IP number.
  DISCOURSE_HOSTNAME: ${Hostname}

  ## Uncomment if you want the container to be started with the same
  ## hostname (-h option) as specified above (default "$hostname-$config")
  #DOCKER_USE_HOSTNAME: true

  ## TODO: List of comma delimited emails that will be made admin and developer
  ## on initial signup example 'user1@example.com,user2@example.com'
  DISCOURSE_DEVELOPER_EMAILS: 'dylan@ordinaryexperts.com'

  ## TODO: The SMTP mail server used to validate new accounts and send notifications
  # SMTP ADDRESS, username, and password are required
  # WARNING the char '#' in SMTP password can cause problems!
  DISCOURSE_SMTP_ADDRESS: $DISCOURSE_SMTP_ADDRESS
  DISCOURSE_SMTP_PORT: 587
  DISCOURSE_SMTP_USER_NAME: $DISCOURSE_SMTP_USER_NAME
  DISCOURSE_SMTP_PASSWORD: "$DISCOURSE_SMTP_PASSWORD"
  #DISCOURSE_SMTP_ENABLE_START_TLS: true           # (optional, default true)
  DISCOURSE_SMTP_DOMAIN: ${Hostname}
  DISCOURSE_NOTIFICATION_EMAIL: noreply@${Hostname}

  ## If you added the Lets Encrypt template, uncomment below to get a free SSL certificate
  LETSENCRYPT_ACCOUNT_EMAIL: dylan@ordinaryexperts.com

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
  - exec: echo "End of custom commands"
EOF
chmod o-rwx /var/discourse/containers/app.yml

echo 'test'
success=$?
cfn-signal --exit-code $success --stack ${AWS::StackName} --resource Asg --region ${AWS::Region}
