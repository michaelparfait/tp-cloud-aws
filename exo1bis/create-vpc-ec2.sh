#!/bin/bash

# AWS VPC Creation Shell Script

# Variables
AWS_REGION="eu-west-3"
VPC_NAME="VPC Michael"
VPC_CIDR="10.0.0.0/16"
SUBNET_PUBLIC_CIDR="10.0.1.0/24"
SUBNET_PUBLIC_AZ="eu-west-3a"
SUBNET_PUBLIC_NAME="10.0.1.0 - eu-west-3a"
SUBNET_PRIVATE_CIDR="10.0.2.0/24"
SUBNET_PRIVATE_AZ="eu-west-3c"
SUBNET_PRIVATE_NAME="10.0.2.0 - eu-west-3b"
CHECK_FREQUENCY=5
KEY_NAME="mickey-key"
GROUP_NAME="mickey-group"
INSTANCE_TYPE="t2.micro"
#AWS_IMAGE="ami-05caec24939a823ee"
AWS_IMAGE="ami-00c08ad1a6ca8ca7c"

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

# Create Private Subnet
echo "Creating Private Subnet..."
SUBNET_PRIVATE_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PRIVATE_CIDR \
  --availability-zone $SUBNET_PRIVATE_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$SUBNET_PRIVATE_ID' CREATED in '$SUBNET_PRIVATE_AZ'" \
  "Availability Zone."

# Add Name tag to Private Subnet
aws ec2 create-tags \
  --resources $SUBNET_PRIVATE_ID \
  --tags "Key=Name,Value=$SUBNET_PRIVATE_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$SUBNET_PRIVATE_ID' NAMED as '$SUBNET_PRIVATE_NAME'."

# Create Internet gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
  --output text \
  --region $AWS_REGION)
echo "  Internet Gateway ID '$IGW_ID' CREATED."

# Attach Internet gateway to your VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $AWS_REGION
echo "  Internet Gateway ID '$IGW_ID' ATTACHED to VPC ID '$VPC_ID'."

# Create Route Table
echo "Creating Route Table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.{RouteTableId:RouteTableId}' \
  --output text \
  --region $AWS_REGION)
echo "  Route Table ID '$ROUTE_TABLE_ID' CREATED."

# Create route to Internet Gateway
echo "Create route to Internet Gateway..."
RESULT=$(aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $AWS_REGION)
echo "  Route to '0.0.0.0/0' via Internet Gateway ID '$IGW_ID' ADDED to" \
  "Route Table ID '$ROUTE_TABLE_ID'."

# Associate Public Subnet with Route Table
echo "Associate Public Subnet with Route Table..."
RESULT=$(aws ec2 associate-route-table  \
  --subnet-id $SUBNET_PUBLIC_ID \
  --route-table-id $ROUTE_TABLE_ID \
  --region $AWS_REGION)
echo "  Public Subnet ID '$SUBNET_PUBLIC_ID' ASSOCIATED with Route Table ID" \
  "'$ROUTE_TABLE_ID'."

# Enable Auto-assign Public IP on Public Subnet
echo "Enable Auto-assign Public IP on Public Subnet..."
aws ec2 modify-subnet-attribute \
  --subnet-id $SUBNET_PUBLIC_ID \
  --map-public-ip-on-launch \
  --region $AWS_REGION
echo "  'Auto-assign Public IP' ENABLED on Public Subnet ID" \
  "'$SUBNET_PUBLIC_ID'."


# Création de l'instance EC2
if aws ec2 wait key-pair-exists --key-names $KEY_NAME
    then
    echo 'La clé existe déjà, on la supprime'
    aws ec2 delete-key-pair --key-name $KEY_NAME
fi

if [ -f ~/.ssh/$KEY_NAME.pem ]
    then
    echo 'La clé existe déjà en local, on la supprime'
    sudo rm -f ~/.ssh/$KEY_NAME.pem
fi

# Création d'une paire clé SSH
echo "Création d'une paire clé SSH..."
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/$KEY_NAME.pem

#echo "Describe key pairs ..."
#aws ec2 describe-key-pairs 
#    --key-name $KEY_NAME

# Définition des bons droits sur la clé SSH
chmod 400 ~/.ssh/$KEY_NAME.pem

# Création du groupe de sécurité
echo "Création du groupe de sécurité..."
GROUP_ID=$(aws ec2 create-security-group \
        --group-name $GROUP_NAME \
        --query 'GroupId' \
        --description "$GROUP_NAME Demo Mickey Security Group" \
        --vpc-id $VPC_ID \
        --output text)

# Ajout d'une règle pour le SSH (port 22)
echo "Ajout d'une règle pour le SSH (port 22)..."
aws ec2 authorize-security-group-ingress \
        --group-id $GROUP_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0

#--group-name $GROUP_NAME \
#--group-id $GROUP_ID \

# Ajout d'une règle pour le HTTP (port 80)
echo "Ajout d'une règle pour le HTTP (port 80)..."
aws ec2 authorize-security-group-ingress \
        --group-id $GROUP_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0

# describe security group
#echo "describe security group..."
#aws ec2 describe-security-groups \
#        --group-names $GROUP_NAME \
#        --output table

# Lancement d'une instance t2.micro
echo "Lancement d'une instance t2.micro..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AWS_IMAGE \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $GROUP_ID \
    --subnet-id $SUBNET_PUBLIC_ID\
    --query 'Instances[0].InstanceId' \
    --output text)

# Récupération de l'IP de l'instance
echo "Récupération de l'IP de l'instance..."
INSTANCE_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text)

# Connexion SSH
ssh -i $KEY_NAME.pem ec2-user@$INSTANCE_IP

# Déploiement de l'application

