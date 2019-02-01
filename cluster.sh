#!/bin/bash

export stack_name=eks-network

# Wait for to complete the clodformation VPC stack
echo "Wait for to complete the clodformation VPC stack"
aws --region "$region" cloudformation wait stack-create-complete --stack-name "$stack_name"

export role=$(aws iam get-role --role-name eks | grep Arn | awk '{print $2}' | sed 's/\"//g')
export securitygroupId=$(aws --region "$region" cloudformation describe-stacks --stack-name  "$stack_name" --query 'Stacks[0].Outputs[0].OutputValue' | sed 's/\"//g')
export vpcid=$(aws --region "$region" cloudformation describe-stacks --stack-name  "$stack_name" --query 'Stacks[0].Outputs[1].OutputValue' | sed 's/\"//g')
export subnetIds=$(aws --region "$region" cloudformation describe-stacks --stack-name  "$stack_name" --query 'Stacks[0].Outputs[2].OutputValue' | sed 's/\"//g')
echo $subnetIds > subnets.txt
export subnet1=$(cat subnets.txt | sed 's/\,/ /g' | awk '{print $1}')
export subnet2=$(cat subnets.txt | sed 's/\,/ /g' | awk '{print $2}')
export subnet3=$(cat subnets.txt | sed 's/\,/ /g' | awk '{print $3}')

export region=us-east-1
export instance_type=t2.medium
export keyname=eks
export ami=ami-dea4d5a1
export cluster_name=eks-k8s
export node_name=worker

export node_as_min_size=3
export node_as_max_size=10
export node_as_desired_size=3

echo "The EKS cluster: $cluster_name is creating, please wait..."
aws --region "$region" eks create-cluster \
	--name "$cluster_name" \
	--role-arn "$role" \
	--resources-vpc-config subnetIds="$subnetIds",securityGroupIds="$securitygroupId"

#aws --region "$region" cloudformation wait stack-create-complete --stack-name "$cluster_name"

aws --region "$region" eks wait cluster-active --name "$cluster_name"


echo "The EKS master is created."

echo "Creating EKS Worker Nodes, please wait..."
aws --region "$region" cloudformation \
	create-stack --stack-name "$node_name" \
	--template-body file://vars-eks-nodegroup.yaml \
	--parameters \
	ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue="$securitygroupId" \
	ParameterKey=NodeGroupName,ParameterValue="$node_name" \
	ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue="$node_as_min_size" \
	ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue="$node_as_max_size" \
	ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue="$node_as_desired_size" \
	ParameterKey=NodeInstanceType,ParameterValue="$instance_type" \
	ParameterKey=NodeImageId,ParameterValue="$ami" \
	ParameterKey=KeyName,ParameterValue="$keyname" \
	ParameterKey=VpcId,ParameterValue="$vpcid" \
	ParameterKey=Subnets,ParameterValue="$subnet1" \
	ParameterKey=Subnets,ParameterValue="$subnet2" \
	ParameterKey=Subnets,ParameterValue="$subnet3" \
	ParameterKey=ClusterName,ParameterValue="$cluster_name" \
	--capabilities CAPABILITY_IAM
echo ''

aws --region "$region" cloudformation wait stack-create-complete --stack-name "$node_name"

echo "Setting up Kubectl"

export url=$(aws --region "$region" eks describe-cluster --name "$cluster_name" --query cluster.endpoint | sed 's/\"//g')
export cert=$(aws --region "$region" eks describe-cluster --name "$cluster_name" --query cluster.certificateAuthority.data | sed 's/\"//g')

sed -e "s@cluster_name@$cluster_name@g" -e "s@endpoint_url@$url@g" -e "s@ca_cert@$cert@g" kubeconfig > /src/.kube/config-$cluster_name

aws --region "$region" cloudformation wait stack-create-complete --stack-name "$node_name"

export node_role=$(aws --region "$region" cloudformation describe-stacks --stack-name "$node_name" --query 'Stacks[0].Outputs[0].OutputValue' | sed 's/\"//g')

sed -e "s@node_instance_role@$node_role@g" auth-node.yaml > /src/node.yaml

echo "setup AWS Config"

export AWS_CONFIG_FILE=/src/.aws/credentials && aws sts get-caller-identity

echo "setup Kubeconfig"

export KUBECONFIG=/src/.kube/config-$cluster_name

echo "Authenticate the nodes with the cluster"

/bin/kubectl apply -f /src/node.yaml

/bin/kubectl get svc

/bin/kubectl get nodes
