-include common.mk

update-common:
	wget -O common.mk https://raw.githubusercontent.com/ordinaryexperts/aws-marketplace-utilities/hotfix/1.6.2/common.mk

deploy: build
	docker compose run -w /code/cdk --rm devenv cdk deploy \
	--require-approval never \
	--parameters AdminEmails=dylan@ordinaryexperts.com \
	--parameters AlbCertificateArn=arn:aws:acm:us-east-1:992593896645:certificate/943928d7-bfce-469c-b1bf-11561024580e \
	--parameters AlbIngressCidr=0.0.0.0/0 \
	--parameters AsgAmiId=ami-0eaa5dd63537eebc4 \
	--parameters AsgReprovisionString=20250312.1 \
	--parameters DnsHostname=discourse-${USER}.dev.patterns.ordinaryexperts.com \
	--parameters DnsRoute53HostedZoneName=dev.patterns.ordinaryexperts.com \
	--parameters VpcId=vpc-00425deda4c835455 \
	--parameters VpcPrivateSubnet1Id=subnet-030c94b9795c6cb96 \
	--parameters VpcPrivateSubnet2Id=subnet-079290412ce63c4d5 \
	--parameters VpcPublicSubnet1Id=subnet-0c2f5d4daa1792c8d \
	--parameters VpcPublicSubnet2Id=subnet-060c39a6ded9e89d7 \
	--parameters PluginCommandsList="git clone https://github.com/discourse/discourse-math.git,git clone https://github.com/discourse/discourse-cakeday.git"
