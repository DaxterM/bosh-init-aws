# bosh-init-aws

Command line tool that
* Automates BOSH AWS infrastructure creation
* Creates bosh deployment manifest containing newly created AWS infrastructure (VPC, Subnets, Elastic IP, etc)
* Creates AWS cloud config containing newly created AWS infrastructure


## Pre-reqs

* AWS CLI https://aws.amazon.com/cli/ (brew install awscli)
* JQ https://stedolan.github.io/jq/ (brew install jq)
* bosh-init https://github.com/cloudfoundry/bosh-init
* bosh CLI https://bosh.io/docs/bosh-cli.html

Run aws configure. The account you setup needs to have full access to EC2 and VPC.
Example:
```
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-west-2
Default output format [None]: ENTER
```
## Usage

## Warning
It is highly recommended that you change default usernames and passwords inside templates/bosh.yml.template. If you do not  you should at least update the security group rules to only allow access from your IP address.

## Deploy bosh director
```
$ git clone https://github.com/DaxterM/bosh-init-aws
$ cd bosh-init-aws
$ AWSAccessKey=Put_Access_Key_Here
$ AWSSecretKey=Put_Secret_Key_Here
$ sed -i -e 's/PUTYOURKEYHERE/'$AWSAccessKey'/g' templates/bosh.yml.template  
$ sed -i -e 's/PUTYOURSECRETHER/'$AWSSecretKey'/g' templates/bosh.yml.template  

$ ./bosh-init-aws.sh
Name of bosh deployment (default:bosh-init-aws-deployment):
My-New-Deployment

Creating Bosh VPC
BoshVPC vpc-xxxxx created

Creating internet gateway and attaching to VPC
Bosh InternetGateway igw-xxxx Created

Adding route to route table for internet gateway
{
    "Return": true
}

Creating  subnet for BoshVPC
Public subnet subnet-xxxx created

Creating Bosh Security Group
sg-xxxxx created

Creating Security group rules
Rules Created

Getting Elastic IP for Bosh Director
Elastic IP x.x.x.x created

Creating bosh key pair
Key Created. Uploading Public Key to AWS
{
    "KeyName": "My-New-Deployment",
    "KeyFingerprint": "x:xx:xx:27:fe:18:02:50:c8:49:b9:de:0f:ac:ca:89"
}

Generating AWS bosh.yml
Bosh manifest created. To deploy a bosh director run:

         cd My-New-Deployment
         bosh-init deploy ./bosh.yml

$ cd My-New-Deployment
$ bosh-init deploy ./bosh.yml
Deployment manifest: '/Users/Dax/labs/bosh-init-aws/My-New-Deployment/bosh.yml'
Deployment state: '/Users/Dax/labs/bosh-init-aws/My-New-Deployment/bosh-state.json'

Started validating
  Downloading release 'bosh'... Skipped [Found in local cache] (00:00:00)
  Validating release 'bosh'... Finished (00:00:00)
  Downloading release 'bosh-aws-cpi'... Skipped [Found in local cache] (00:00:00)
  Validating release 'bosh-aws-cpi'... Finished (00:00:00)
  Validating cpi release... Finished (00:00:00)
  Validating deployment manifest... Finished (00:00:00)
  Downloading stemcell... Skipped [Found in local cache] (00:00:00)
  Validating stemcell... Finished (00:00:00)
Finished validating (00:00:00)

Started installing CPI
  Compiling package 'ruby_aws_cpi/5e8696452d4676dd97010e91475e86b23b7e2042'... Finished (00:02:24)
  Compiling package 'bosh_aws_cpi/4f3048d0cfa10550d62c73d5c7cc67e97658aeeb'... Finished (00:01:04)
  Installing packages... Finished (00:00:00)
  Rendering job templates... Finished (00:00:00)
  Installing job 'aws_cpi'... Finished (00:00:00)
Finished installing CPI (00:03:30)

Starting registry... Finished (00:00:00)
Uploading stemcell 'bosh-aws-xen-hvm-ubuntu-trusty-go_agent/3312'... Finished (00:00:08)

Started deploying
  Creating VM for instance 'bosh/0' from stemcell 'ami-7fa58e68 light'... Finished (00:00:30)
  Waiting for the agent on VM 'i-xxxxxxx' to be ready... Finished (00:01:32)
  Creating disk... Finished (00:00:12)
  Attaching disk 'vol-xxxxxxx' to VM 'i-xxxxxxx'... Finished (00:00:14)
  Rendering job templates... Finished (00:00:04)
  Compiling package 'ruby_aws_cpi/5e8696452d4676dd97010e91475e86b23b7e2042'... Finished (00:03:04)
  Compiling package 'ruby/589d4b05b422ac6c92ee7094fc2a402db1f2d731'... Finished (00:02:14)
  Compiling package 'mysql/b7e73acc0bfe05f1c6cbfd97bf92d39b0d3155d5'... Finished (00:00:31)
  Compiling package 'libpq/09c8f60b87c9bd41b37b0f62159c9d77163f52b8'... Finished (00:00:18)
  Compiling package 's3cli/8cbc6ee1b5acaac18c63fafc5989bd6911c9be83'... Finished (00:00:02)
  Compiling package 'davcli/5f08f8d5ab3addd0e11171f739f072b107b30b8c'... Finished (00:00:01)
  Compiling package 'bosh_aws_cpi/4f3048d0cfa10550d62c73d5c7cc67e97658aeeb'... Finished (00:00:58)
  Compiling package 'nats/0155cf6be0305c9f98ba2e9e2503cd72da7c05c3'... Finished (00:00:17)
  Compiling package 'registry/02be563161fd57b6a9a3a0e2c572ea310bd9085f'... Finished (00:01:18)
  Compiling package 'health_monitor/b3ea0030f0b6cbe12b380cb07d498e12dac5723c'... Finished (00:01:12)
  Compiling package 'director/3b6aecde68525c82796a6ce1e19f29a611984267'... Finished (00:01:30)
  Compiling package 'nginx/21e909d27fa69b3b2be036cdf5b8b293c6800158'... Finished (00:00:45)
  Compiling package 'postgres/4b9f6514001f7c3f7d4394920d6aced9435a3bbd'... Finished (00:04:11)
  Updating instance 'bosh/0'... Finished (00:00:15)
  Waiting for instance 'bosh/0' to be running... Finished (00:00:26)
  Running the post-start scripts 'bosh/0'... Finished (00:00:00)
Finished deploying (00:19:42)

Stopping registry... Finished (00:00:00)
Cleaning up rendered CPI jobs... Finished (00:00:00)
```

## Upload Cloud config
```
$ bosh target Elastic_IP_Here
$ bosh upload cloud-config Deployment_Name_Here/cloud.yml
```
## Destroy bosh director
```
$ ./bosh-destroy-aws.sh
Name of bosh deployment to Delete (default:bosh-init-aws-deployment):
My-New-Deployment
Bosh director instance id is i-0XXXXXXXXXX. Terminating it now
{
    "TerminatingInstances": [
        {
            "InstanceId": "i-XXXXXXXXXXX",
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
Terminate command issued. Waiting for it to complete
instance terminated
Deleting elastic ip
Deleting Security group
detaching internet gateway
Deleting internet gateway
Deleting bosh subnet
Deleting VPC
Deleting Keypair

```
