#!/bin/bash

base_name=${1-cf-ss-example}

set -e

which jq
which aws

account_id=`aws sts get-caller-identity | jq -r ".Account"`

set -x

aws cloudformation validate-template --template-body=file://template.yml
aws cloudformation validate-template --template-body=file://template-infra.yml

aws ec2 delete-key-pair --key-name $base_name

aws ec2 import-key-pair \
	--key-name $base_name \
	--public-key-material "$(cat saltstack/keys/ssh.pub)"

aws --region eu-central-1 cloudformation create-stack \
	--template-body=file://template-infra.yml \
	--stack-name=$base_name-infra

aws --region eu-central-1 cloudformation wait stack-create-complete --stack-name $base_name-infra
bucket_name=`aws cloudformation describe-stacks --stack-name $base_name-infra | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "ConfigBucketName").OutputValue'`
aws --region eu-central-1 s3 cp --recursive saltstack/ s3://$bucket_name

aws --region eu-central-1 cloudformation create-stack \
	--template-body=file://template.yml \
	--stack-name=$base_name \
	--parameters \
		ParameterKey=InfraStackName,ParameterValue=$base_name-infra \
		ParameterKey=KeyName,ParameterValue=$base_name \
	--capabilities CAPABILITY_IAM

aws --region eu-central-1 cloudformation wait stack-create-complete --stack-name $base_name
salt_master_ip=`aws cloudformation describe-stacks --stack-name $base_name | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "SaltMasterIpAddress").OutputValue'`
web_ip=`aws cloudformation describe-stacks --stack-name $base_name | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "WebIpAddress").OutputValue'`

sleep 3 # NOTE: time for the minions to get ready (maybe)

ssh -i saltstack/keys/ssh -o StrictHostKeyChecking=no ubuntu@$salt_master_ip sudo salt database state.apply database
ssh -i saltstack/keys/ssh -o StrictHostKeyChecking=no ubuntu@$salt_master_ip sudo salt web state.apply web

echo "Web service available at: $web_ip"
echo "Salt Master available at: $salt_master_ip"

curl -si --retry 3 --retry-delay 2 http://$web_ip
