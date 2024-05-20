# Vi Technologies Home Assignment

This repository contains the infrastructure and deployment configuration for the solution of the home assigment of the interview process for DevOps role in Vi Technologies. It includes Terraform scripts for provisioning AWS resources and Helm charts for deploying the services to an EKS cluster.

## Prerequisites

Before you start, ensure you have the following installed:

1. **Terraform**: [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2. **AWS CLI**: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
3. **kubectl**: [Installation Guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
4. **Helm**: [Installation Guide](https://helm.sh/docs/intro/install/)
5. **Docker**: [Installation Guide](https://docs.docker.com/get-docker/)
6. **Git**: [Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

You will also need AWS credentials configured on your machine. You can set this up by running `aws configure` and providing your AWS access key and secret key.


## Repository Structure

```plaintext
.
├── packages                 # Provided by the recruiting team, includes 2 applications
├── 1-remote-state           # Terraform provisioning of S3 backend and DynamoDB table for state locking
├── 2-setup                  # Terraform provisioning of ECR repository and OIDC for GitHub to AWS IAM connection
├── 3-eks                    # Terraform provisioning of VPC, EKS, MongoDB, CAS, Prometheus & Grafana, and ALB Ingress
├── 4-charts                 # Helm charts for deploying the services
└── README.md                # This file
```


## Directory Descriptions

- **packages**: Contains the NodeJS applications that need to be deployed.
- **1-remote-state**: Terraform scripts for setting up the remote state management using S3 and DynamoDB.
- **2-setup**: Terraform scripts for creating an ECR repository and setting up OIDC to allow GitHub Actions to interact with AWS.
- **3-eks**: Terraform scripts for creating the VPC, EKS cluster, deploying MongoDB within the cluster, setting up Cluster Autoscaler, Prometheus & Grafana for monitoring, and ALB Ingress for exposing services.
- **4-charts**: Helm charts for deploying the NodeJS applications in the packages directory.


## Deployment Steps

1. **Set Up Remote State**

   Navigate to the `1-remote-state` directory and initialize and apply the Terraform configuration:

   ```sh
   cd 1-remote-state
   terraform init
   terraform apply
   ```

2. **Provision ECR and OIDC**

   Navigate to the `2-setup` directory and initialize and apply the Terraform configuration:

   ```sh
   cd 2-setup
   terraform init
   terraform apply
   ```

3. **Create EKS Cluster and Deploy Resources**

   Navigate to the `3-eks` directory and initialize and apply the Terraform configuration:

   ```sh
   cd 3-eks
   terraform init
   terraform apply
   ```


## Testing

To verify the deployment, follow these steps:

1. **Access the Applications**: You can access the application using the following scripts:

    ```sh
    curl -X POST "http://k8s-default-albingre-cf77fcd55d-2074889912.us-west-2.elb.amazonaws.com/orders" -H "Host: service1.vi-technologies.com"
    
    curl -X DELETE "http://k8s-default-albingre-cf77fcd55d-2074889912.us-west-2.elb.amazonaws.com/orders/:id" -H "Host: service1.vi-technologies.com"
    
    curl -X GET "http://k8s-default-albingre-cf77fcd55d-2074889912.us-west-2.elb.amazonaws.com/orders" -H "Host: service2.vi-technologies.com"
    ```

2. **Monitor the Cluster**: You can monitor the cluster using Grafana, which is exposed at the following URL (will be provided later). Use the following credentials to login: Username = admin, Password = prom-operator.


## GitHub Actions Workflows

This section describes the GitHub Actions workflows included in this repository:

1. **eks-deployment.yml**: This workflow deploys the EKS cluster from the "3-eks" folder on every push or pull request.

2. **service1-ci.yml**: This workflow implements CI/CD for service1. It deploys the service1 from the "packages/service1" directory on every push or pull request.

3. **service2-ci.yml**: This workflow implements CI/CD for service2. It deploys the service2 from the "packages/service2" directory on every push or pull request.


