# Docker-EKS

- Amazon Elastic Container Service for Kubernetes (Amazon EKS) is a managed service that makes it easy for you to run Kubernetes on AWS without needing to stand up or maintain your own Kubernetes control plane.

- Amazon EKS runs Kubernetes control plane instances across multiple Availability Zones to ensure high availability. Amazon EKS automatically detects and replaces unhealthy control plane instances, and it provides automated version upgrades and patching for them.

- Amazon EKS is also integrated with many AWS services to provide scalability and security for your applications, including the following:
    • Elastic Load Balancing for load distribution
    • IAM for authentication
    • AmazonVPCforisolation


#### Building the AWS EKS from scratch by keeping all dependencies & setup execution inside a container. By building the image, the container will do the below tasks:

   • `Creating an AWS EKS service role`

   • `Creating an AWS EKS Cluster VPC`

   • `Install and Configure kubectl for Amazon EKS`

   • `Creating an AWS EKS cluster`

   • `Configure kubectl for Amazon EKS`

   • `Launch and Configure Amazon EKS Worker Nodes`



# Variables to change:

`vars-eks-vpc.yaml` file defines your VPC network. You can change the CIDR on the file.

```

  VpcBlock:
    Type: String
    Default: 10.16.0.0/16
    Description: The CIDR range for the VPC.

  Subnet01Block:
    Type: String
    Default: 10.16.1.0/24
    Description: CidrBlock for subnet 01 within the VPC

  Subnet02Block:
    Type: String
    Default: 10.16.2.0/24
    Description: CidrBlock for subnet 02 within the VPC

  Subnet03Block:
    Type: String
    Default: 10.16.3.0/24
    Description: CidrBlock for subnet 03 within the VPC


```

`cluster.sh` file is script to build the EKS cluster.

```

export region=us-east-1
export instance_type=t2.medium
export keyname=eks
export ami=ami-dea4d5a1
export cluster_name=eks-master
export node_name=eks-worker

```

### Run the below command and grab a cup of coffee because it will take some [time](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)

Open the `vars-eks-vpc.yaml` & `cluster.sh` and update with your Variables. Then build the docker image.

```
Fill the AWS variables in the Makefile & type

 make

```

## OR

```
 git clone https://github.com/vishnudxb/docker-eks.git && cd docker-eks

 docker build --build-arg AWS_ACCESS_KEY=<Put your access key> --build-arg AWS_SECRET_KEY=<put your secret key> --build-arg REGION=<Your AWS Region> vishnudxb/docker-eks

```

#### Please be aware that setting the ARG and ENV values leaves traces in the Docker image.
