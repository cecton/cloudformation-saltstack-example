#!/bin/bash

base_name=${1-cf-ss-example}

set -e

which jq
which aws

set -x

aws --region eu-central-1 cloudformation delete-stack --stack-name=$base_name
aws --region eu-central-1 cloudformation wait stack-delete-complete --stack-name $base_name

bucket_name=`aws cloudformation describe-stacks --stack-name $base_name-infra | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "ConfigBucketName").OutputValue'`
aws --region eu-central-1 s3 rm --recursive s3://$bucket_name/

aws --region eu-central-1 cloudformation delete-stack --stack-name=$base_name-infra
aws --region eu-central-1 cloudformation wait stack-delete-complete --stack-name $base_name-infra

aws ec2 delete-key-pair --key-name $base_name
