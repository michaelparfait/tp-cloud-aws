#!/usr/bin/env bash

STACK_NAME="micheystack"
INSTANCE_TYPE="t2.micro"
DIR="/home/ec2-user/tp2-cloud-formation"
AWS_REGION="eu-west-3"

TYPE_CLOUD_FORMATION=""

#aws cloudformation wait stack-exists \
#    --stack-name $STACK_NAME

echo "Checking if stack exists ..."
if ! aws cloudformation describe-stacks --region $AWS_REGION --stack-name $STACK_NAME ; then
    echo -e "Stack $STACK_NAME does not exist...Creating"
    TYPE_CLOUD_FORMATION='create-stack'
else
     echo -e "Stack $STACK_NAME exist, update $STACK_NAME"
    TYPE_CLOUD_FORMATION='update-stack'
fi

echo "Creating and actualization stack..."
STACK_ID=$(aws cloudformation validate-template $TYPE_CLOUD_FORMATION  \
        --region $AWS_REGION  \
        --stack-name $STACK_NAME  \
        --template-body file//$DIR/create-update-stack.yml \
        --parameters  file://$DIR/parameters/michey-parameters.json \
)

echo "Waiting on ${STACK_ID} create completion..."
ws cloudformation wait stack-create-complete --stack-name ${STACK_ID}

echo "Describe stacks ..."
aws --region $api_region cloudformation describe-stacks --stack-name $STACK_NAME