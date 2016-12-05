#!/bin/bash


if ! type "jq" > /dev/null; then # Check That JQ is installed
  echo JQ not installed. Install JQ  https://stedolan.github.io/jq/. Exiting && exit 1;
fi

if ! type "aws" > /dev/null; then # Check That aws cli is installed
  echo aws not installed. Install aws cli. Exiting && exit 1;
fi



echo "Name of bosh deployment to Delete (default:bosh-init-aws-deployment):"
read DeploymentName
[ -z "$DeploymentName" ] && DeploymentName=bosh-init-aws-deployment



if [ -d !"$DeploymentName" ]; then
  echo "No deployment with name $DeploymentName found Exiting" && exit 1;
fi

cd $DeploymentName

source awsoutputs



DirectorInstanceId="$(cat bosh-state.json | jq -r .current_vm_cid)"


echo "Bosh director instance id is $DirectorInstanceId. Terminating it now"

aws ec2  terminate-instances  --instance-ids $DirectorInstanceId

echo "Terminate command issued. Waiting for it to complete"

aws ec2 wait instance-terminated  --instance-ids $DirectorInstanceId

echo "instance terminated"


echo "Deleting elastic ip"
aws ec2 release-address --allocation-id $AllocationId

echo "Deleting Security group"
aws ec2 delete-security-group --group-id $GroupId


echo "detaching internet gateway"
aws ec2 detach-internet-gateway --internet-gateway-id ${InternetGatewayId} --vpc-id ${VpcId}

echo "Deleting internet gateway"
aws ec2 delete-internet-gateway --internet-gateway-id ${InternetGatewayId}

echo "Deleting bosh subnet"
aws ec2 delete-subnet --subnet-id $SubnetID

echo "Deleting VPC"
aws ec2 delete-vpc --vpc-id $VpcId

echo "Deleting Keypair"
aws ec2 delete-key-pair --key-name $DeploymentName
