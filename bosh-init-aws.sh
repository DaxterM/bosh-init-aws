#!/bin/bash


if ! type "jq" > /dev/null; then # Check That JQ is installed
  echo JQ not installed. Install JQ  https://stedolan.github.io/jq/. Exiting && exit 1;
fi

if ! type "aws" > /dev/null; then # Check That aws cli is installed
  echo aws not installed. Install aws cli. Exiting && exit 1;
fi



echo "Name of bosh deployment (default:bosh-init-aws-deployment):"
read DeploymentName
[ -z "$DeploymentName" ] && DeploymentName=bosh-init-aws-deployment



if [ -d "$DeploymentName" ]; then
  echo "Deployment directory with name $DeploymentName already exists. Exiting" && exit 1;
fi


mkdir $DeploymentName
cd $DeploymentName


echo -e "\nCreating Bosh VPC"
VpcId="$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 | jq -r .Vpc.VpcId)"
echo "BoshVPC ${VpcId} created"

#Name the VPC for clarity in the UI
aws ec2 create-tags --resources ${VpcId} --tags Key=Name,Value=$DeploymentName
#Enable DNS hostname resolution on the VPC
aws ec2 modify-vpc-attribute --vpc-id ${VpcId} --enable-dns-hostnames


echo -e "\nCreating internet gateway and attaching to VPC"
InternetGatewayId="$(aws ec2 create-internet-gateway | jq -r .InternetGateway.InternetGatewayId)"
aws ec2 attach-internet-gateway --internet-gateway-id ${InternetGatewayId} --vpc-id ${VpcId}
echo "Bosh InternetGateway ${InternetGatewayId} Created"



echo -e "\nAdding route to route table for internet gateway"
RouteTableId="$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VpcId}" | jq -r .RouteTables[0].RouteTableId)"
aws ec2 create-route --route-table-id ${RouteTableId} --destination-cidr-block 0.0.0.0/0 --gateway-id ${InternetGatewayId}



echo -e "\nCreating  subnet for BoshVPC"
SubnetId="$(aws ec2 create-subnet --vpc-id ${VpcId} --availability-zone us-east-1a --cidr-block 10.0.0.0/24 | jq -r .Subnet.SubnetId)"
echo "Public subnet ${SubnetId} created"



echo -e "\nCreating Bosh Security Group"
GroupId="$(aws ec2 create-security-group --vpc-id ${VpcId} --group-name $DeploymentName --description "$DeploymentName deployed vms" | jq -r .GroupId)"
echo "${GroupId} created"



echo -e "\nCreating Security group rules"
aws ec2 authorize-security-group-ingress --group-id ${GroupId} --protocol all  --source-group ${GroupId}
aws ec2 authorize-security-group-ingress --group-id ${GroupId} --protocol tcp --port 22  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${GroupId} --protocol tcp --port 6868  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${GroupId} --protocol tcp --port 25555  --cidr 0.0.0.0/0
echo "Rules Created"



echo -e "\nGetting Elastic IP for Bosh Director"
PublicIp="$(aws ec2 allocate-address | jq -r .PublicIp)"
AllocationId="$(aws ec2 describe-addresses --public-ips  ${PublicIp}| jq -r .Addresses[0].AllocationId)"
echo "Elastic IP ${PublicIp} created"



echo -e "\nCreating bosh key pair "
mkdir KeyPair
cd KeyPair
ssh-keygen -t rsa -C "$DeploymentName" -f $DeploymentName -q -N ""
echo "Key Created. Uploading Public Key to AWS"
aws  ec2 \
import-key-pair \
--key-name "$DeploymentName" \
--public-key-material file://$DeploymentName.pub
cd ..



echo "VpcId=${VpcId}" > awsoutputs
echo "InternetGatewayId=${InternetGatewayId}" >> awsoutputs
echo "SubnetID=${SubnetId}" >> awsoutputs
echo "GroupId=${GroupId}" >> awsoutputs
echo "PublicIp=${PublicIp}" >> awsoutputs
echo "AllocationId=${AllocationId}" >> awsoutputs


echo -e "\nGenerating AWS bosh.yml"

cp ../templates/bosh.yml.template  bosh.yml


sed -i '.template' 's/VpcId/'${VpcId}'/g;s/SubnetID/'${SubnetId}'/g;s/GroupId/'${GroupId}'/g;s/PublicIp/'${PublicIp}'/g;s/BIA-DeploymentName/'${DeploymentName}'/g;s/BOSHSECURITYGROUP/'${DeploymentName}'/g' bosh.yml
rm bosh.yml.template


echo -e "Bosh manifest created. To deploy a bosh director run:

         cd $DeploymentName
         bosh-init deploy ./bosh.yml"
