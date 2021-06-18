#!/bin/bash

# AWS VPC Creation Shell Script

# Variables
AWS_REGION="eu-west-3"
VPC_NAME="VPC Mickey"
VPC_CIDR="10.0.0.0/16"
SUBNET_PUBLIC_CIDR="10.0.1.0/24"
SUBNET_PUBLIC_AZ="eu-west-3a"
SUBNET_PUBLIC_NAME="10.0.1.0 - eu-west-3a"
SUBNET_PRIVATE_CIDR="10.0.2.0/24"
SUBNET_PRIVATE_AZ="eu-west-3c"
SUBNET_PRIVATE_NAME="10.0.2.0 - eu-west-3b"
CHECK_FREQUENCY=5
LABID="${USER}${RANDOM}"
export AWS_SGID="sg-0a518bf1e2fd2cc83"
export AWS_IMAGE="ami-05caec24939a823ee"

# Create VPC
echo "Creating VPC in preferred region..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text \
  --region $AWS_REGION)
echo "  VPC ID '$VPC_ID' CREATED in '$AWS_REGION' region."

# Add Name tag to VPC
aws ec2 create-tags \
  --resources $VPC_ID \
  --tags "Key=Name,Value=$VPC_NAME" \
  --region $AWS_REGION
echo "  VPC ID '$VPC_ID' NAMED as '$VPC_NAME'."

# Create Public Subnet
echo "Creating Public Subnet..."
SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PUBLIC_CIDR \
  --availability-zone $SUBNET_PUBLIC_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$SUBNET_PUBLIC_ID' CREATED in '$SUBNET_PUBLIC_AZ'" \
  "Availability Zone."

# Add Name tag to Public Subnet
aws ec2 create-tags \
  --resources $SUBNET_PUBLIC_ID \
  --tags "Key=Name,Value=$SUBNET_PUBLIC_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$SUBNET_PUBLIC_ID' NAMED as" \
  "'$SUBNET_PUBLIC_NAME'."

# Add create security group
aws ec2 create-security-group \
        --group-name $LABID-demo-mickey \
        --description "$LABID Demo Mickey Security Group" \
        --vpc-id $VPC_ID

# Add authorize security group
aws ec2 authorize-security-group-ingress \
        --group-name $LABID-demo-mickey \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0

# Add authorize security group
aws ec2 authorize-security-group-ingress \
        --group-name $LABID-demo-mickey \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0
        
aws ec2 authorize-security-group-ingress \
        --group-name $LABID-demo-mickey \
        --protocol tcp \
        --port 3000 \
        --cidr 0.0.0.0/0

# describe security group
aws ec2 describe-security-groups \
        --group-names $LABID-demo-mickey \
        --output table

# Création de l'instance EC2

# Clé d’accès
aws ec2 create-key-pair 
    --key-name $LABID-demo-mickey-key 
    --query 'KeyMaterial' 
    --output text > ~/.ssh/$LABID-demo-mickey-key.pem

aws ec2 describe-key-pairs 
    --key-name $LABID-demo-mickey-key

# Restreindre les droits
chmod 400 ~/.ssh/$LABID-demo-mickey-key.pem

# Lancer une instance t2.micro
aws ec2 run-instances \
    --instance-type t2.micro \
    --key-name $LABID-demo-mickey-key \
    --security-group-ids $AWS_SGID \
    --image-id $AWS_IMAGE

