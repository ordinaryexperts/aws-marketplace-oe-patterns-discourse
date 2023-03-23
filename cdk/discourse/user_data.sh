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

export DISCOURSE_SMTP_ADDRESS="email-smtp.${Region}.amazonaws.com"
export DISCOURSE_SMTP_USER_NAME=$(cat /opt/oe/patterns/instance-secret.json | jq -r .access_key_id)
export DISCOURSE_SMTP_PASSWORD=$(cat /opt/oe/patterns/instance-secret.json | jq -r .smtp_password)

echo 'test'
success=$?
cfn-signal --exit-code $success --stack ${AWS::StackName} --resource Asg --region ${AWS::Region}
