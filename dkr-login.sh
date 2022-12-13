#!/bin/bash

###############################################################################
# See: 
###############################################################################
echo "Your AWS_PROFILE is ${AWS_PROFILE}, getting your account id..."
[ -z ${AWS_PROFILE} ] && exit 1
[ -z ${AWS_REGION} ] && exit 1
ACC=$(aws sts get-caller-identity|jq ".Account" | tr -d '"')
echo "Your AWS account    ${ACC}"
echo "Your AWS region     ${AWS_REGION}"

REG=${ACC}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker logout 
aws ecr get-login-password --region ${AWS_REGION}| docker login --username AWS --password-stdin ${REG}

echo $REG
