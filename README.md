# Streamlit AWS DevOps Automation Platform

## 1. Project Overview

This project demonstrates an end-to-end AWS DevOps workflow for deploying a Python Streamlit application on Amazon Elastic Kubernetes Service (Amazon EKS).

The project combines Infrastructure as Code (IaC), CI/CD automation, containerization, container image management, Kubernetes orchestration, and application exposure through an AWS Application Load Balancer.

Terraform is used to provision the AWS infrastructure required by the lab, including networking resources, IAM roles and policies, Amazon ECR, the EKS cluster, EKS add-ons, and the managed node group.

Jenkins automates source code checkout, application testing, Docker image creation, pushing images to Amazon ECR, and deployment to Kubernetes. A GitHub webhook triggers the Jenkins pipeline when code is pushed.

## 2. Project Objectives

- Provision AWS infrastructure using Terraform.
- Create a VPC and required networking resources.
- Configure IAM roles, policies, and an instance profile for the lab.
- Create an Amazon ECR repository for application images.
- Provision an Amazon EKS cluster and managed node group using Terraform.
- Automate application delivery using Jenkins.
- Trigger CI/CD using a GitHub webhook.
- Run Python application tests before building the container image.
- Build and publish Docker images to Amazon ECR.
- Deploy the application using Kubernetes manifests.
- Expose the application through an AWS Application Load Balancer.
- Configure Kubernetes Horizontal Pod Autoscaler (HPA).
- Troubleshoot AWS, Terraform, Jenkins, Docker, and Kubernetes issues.

## 3. Project Architecture

```text
Developer
   |
   | Git Push
   v
GitHub Repository
   |
   | GitHub Webhook
   v
Jenkins on EC2
   |
   +--> Checkout Source Code
   |
   +--> Install Dependencies and Run Tests
   |
   +--> Build Docker Image
   |
   +--> Push Image to Amazon ECR
   |
   +--> Deploy Application to Amazon EKS
             |
             v
       Amazon EKS Cluster
             |
             v
       Managed Node Group
             |
             v
       Kubernetes Deployment
             |
             +--> Streamlit Pod 1
             |
             +--> Streamlit Pod 2
             |
             +--> Horizontal Pod Autoscaler
             |
             v
       Kubernetes Service
             |
             v
       Kubernetes Ingress
             |
             v
       AWS Application Load Balancer
             |
             v
       User's Browser
```

### Infrastructure provisioning flow

```text
Terraform Configuration
        |
        v
Terraform Init, Validate, Plan and Apply
        |
        +--> VPC and Subnets
        +--> Internet Gateway and Route Tables
        +--> Security Groups
        +--> IAM Roles and Policies
        +--> Amazon ECR Repository
        +--> Amazon EKS Cluster and Add-ons
        +--> EKS Managed Node Group
        +--> Jenkins IAM Instance Profile
        +--> EKS Access for Jenkins
```

## 4. Technologies Used

| Technology | Purpose |
|---|---|
| AWS EC2 | Jenkins server and lab administration |
| AWS IAM | AWS permissions and service roles |
| Amazon VPC | Network isolation and connectivity |
| Amazon ECR | Docker image registry |
| Amazon EKS | Managed Kubernetes control plane |
| EKS Managed Node Group | EC2 worker nodes for application workloads |
| Terraform | Infrastructure as Code |
| Git | Version control |
| GitHub | Source code repository |
| GitHub Webhook | Automatic pipeline trigger |
| Jenkins | CI/CD automation |
| Python | Application programming language |
| Streamlit | Web application framework |
| Pytest | Automated application tests |
| Docker | Application containerization |
| Kubernetes | Container orchestration |
| Kubernetes HPA | Horizontal pod autoscaling |
| AWS Load Balancer Controller | Connects Kubernetes Ingress with AWS load balancing |
| AWS Application Load Balancer | External HTTP access |
| kubectl | Kubernetes administration |

## 5. Repository Structure

The project repository contains the application, pipeline, Kubernetes manifests, and Terraform configuration.

```text
streamlit-aws-devops/
├── app.py
├── requirements.txt
├── Dockerfile
├── .dockerignore
├── .gitignore
├── Jenkinsfile
├── README.md
├── tests/
│   └── test_app.py
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   └── ingress.yaml
└── terraform/
    ├── versions.tf
    ├── variables.tf
    ├── main.tf
    └── outputs.tf
```

The exact Terraform files may differ depending on the implementation. The committed files in the repository are the source of truth.

## 6. Terraform Infrastructure as Code

Terraform is used to define and provision the AWS infrastructure required by the project.
### AWS resources

- **Amazon VPC:** Provides the network for the EKS environment.
- **Two public subnets:** Host the EKS worker nodes in the configured Availability Zones.
- **Internet Gateway and public route table:** Provide the configured internet route.
- **Security groups:** Control network traffic to the EKS cluster and worker nodes.
- **IAM roles and policies:** Provide permissions for EKS, worker nodes, and Jenkins automation.
- **Amazon ECR:** Stores the application's Docker images.
- **Amazon EKS cluster:** Provides the managed Kubernetes control plane.
- **EKS add-ons:** Provide cluster networking, DNS, and other required functionality.
- **Managed node group:** Provides EC2 worker nodes for Kubernetes workloads.
- **Jenkins IAM instance profile:** Allows Jenkins to access permitted AWS APIs through its attached IAM role.
- **EKS access configuration:** Allows the configured Jenkins identity to authenticate and access the cluster.

**Networking note:** This lab uses public subnets and an Internet Gateway. It does not create private subnets or a NAT Gateway. Review the security group rules and public exposure before adapting this lab for production.
### Terraform workflow

### Terraform-managed infrastructure and IAM

Terraform provisions the VPC, public subnets, Internet Gateway, route table associations, security groups, EKS cluster, managed node group, EKS add-ons, ECR repository, and the project's main IAM roles and EKS access entries.

The initial EC2 bootstrap role is created before Terraform is run because Terraform requires AWS credentials with sufficient permissions to create the infrastructure. This bootstrap role is attached to the EC2 instance and is not the EKS cluster role or worker-node role.

Terraform creates the following roles:

- `streamlit-eks-cluster-role` — EKS control-plane permissions.
- `streamlit-eks-node-role` — worker-node permissions.
- `streamlit-devops-jenkins-role` — ECR access and EKS deployment permissions.

The AWS Load Balancer Controller also requires a dedicated IAM role and OIDC trust configuration. These resources must be added to the Terraform configuration before claiming that the controller's IAM configuration is fully managed by Terraform.

The lab uses public subnets and an Internet Gateway. Restrict the EKS API endpoint to approved client addresses, protect Jenkins with appropriate access controls, and remove temporary lab infrastructure when it is no longer required.

The Terraform workflow includes:

1. Initialize the working directory.
2. Format and validate the configuration.
3. Review the proposed infrastructure changes.
4. Apply the reviewed changes.
5. Verify the infrastructure in AWS.
6. Check Terraform state and resource ownership.

Commands:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Apply changes only after reviewing the plan:

```bash
terraform apply
```

**Important:** Run Terraform from the correct working directory and use the state file associated with that configuration. Do not initialize a new state or apply a different configuration against existing infrastructure without confirming resource ownership.

`terraform validate` checks configuration syntax and internal consistency. It does not prove that resources exist or that an application is healthy.

## 7. Jenkins CI/CD Pipeline

The `Jenkinsfile` defines the automated application build and deployment process.

### Stage 1: Checkout

Jenkins checks out the application source code from GitHub and the configured branch.

### Stage 2: Test

Jenkins installs the required Python dependencies and runs automated tests.

If tests fail, the pipeline should stop before publishing or deploying the application.

### Stage 3: Verify AWS and EKS

The pipeline verifies AWS identity, confirms EKS availability, configures Kubernetes access, and checks connectivity to the cluster.

Jenkins uses the configured EC2 IAM role instead of storing long-lived AWS access keys in the repository.

### Stage 4: Build Docker Image

Jenkins builds the application container image using the repository's Dockerfile.

### Stage 5: Push Image to Amazon ECR

Jenkins authenticates to Amazon ECR and pushes the image using a versioned tag, such as the Jenkins build number.

### Stage 6: Deploy to EKS

Jenkins applies Kubernetes manifests with the correct ECR image URI and waits for the application rollout to complete.

### Stage 7: Verify Deployment

The deployment is verified using Kubernetes commands to check pods, services, rollout status, HPA, and Ingress.


## 8. GitHub Webhook Integration

A GitHub webhook connects repository changes to Jenkins.

When a developer pushes a commit, GitHub sends an event to the configured Jenkins endpoint. Jenkins uses the event to trigger the configured pipeline.

The webhook must point to the correct Jenkins URL, and Jenkins must be reachable from GitHub. For production use, secure the endpoint with HTTPS and restrict access appropriately.

### Prerequisites

- Configure the GitHub webhook to reach your Jenkins endpoint.
- Configure Jenkins with the appropriate pipeline job and repository.
- Ensure the Jenkins instance is reachable by GitHub and the webhook is configured to trigger the pipeline.
- Configure the AWS Load Balancer Controller separately from the EKS cluster provisioning.
- Create or configure the controller's IAM role with the appropriate permissions and EKS OIDC trust relationship.
- Configure the Kubernetes service account in the `kube-system` namespace with the correct IAM role annotation.
- Verify that the AWS Load Balancer Controller is running before expecting the Kubernetes Ingress to provision an AWS Application Load Balancer.

**Important:** Creating the EKS cluster does not automatically configure the GitHub webhook or complete the AWS Load Balancer Controller setup. These components must be configured and verified separately.


## 9. Kubernetes Configuration

| Resource | Configuration |
|---|---|
| Namespace | `streamlit` |
| Deployment | `streamlit-app` |
| Service | `streamlit-service` |
| Container port | `8501` |
| Service port | `80` |
| Initial application replicas | `2` |
| HPA minimum replicas | `2` |
| HPA maximum replicas | `5` |
| HPA CPU target | `50%` |
| Ingress | `streamlit-ingress` |
| Ingress class | `alb` |
| External entry point | AWS Application Load Balancer |

### Application traffic flow

1. The user sends an HTTP request to the ALB hostname.
2. The ALB forwards traffic to the configured Kubernetes targets.
3. The Kubernetes Service provides access to the application pods.
4. The Streamlit application listens on container port `8501`.

The HPA adjusts the number of pod replicas according to configured metrics. Scaling depends on a working metrics API, resource requests, and available cluster capacity.

## 10. Deployment Verification

Run the following commands from an environment with the correct AWS credentials and Kubernetes permissions.

### Verify AWS identity

```bash
aws sts get-caller-identity
```

### Verify EKS cluster status

```bash
aws eks describe-cluster \
  --name streamlit-eks \
  --region ap-south-1 \
  --query 'cluster.status' \
  --output text
```

### Verify Kubernetes nodes

```bash
kubectl get nodes
```

### Verify application pods

```bash
kubectl get pods -n streamlit
```

### Verify deployments and services

```bash
kubectl get deployment,service -n streamlit
```

### Verify deployment rollout

```bash
kubectl rollout status deployment/streamlit-app -n streamlit
```

### Verify HPA

```bash
kubectl get hpa -n streamlit
```

### Verify pod metrics

```bash
kubectl top pods -n streamlit
```

### Verify Ingress and ALB hostname

```bash
kubectl get ingress streamlit-ingress -n streamlit
```

### Verify ECR images

```bash
aws ecr describe-images \
  --region ap-south-1 \
  --repository-name streamlit-app \
  --output table
```

## 11. Troubleshooting Experience

### Issue 1: Kubernetes pod entered `ErrImagePull`

**Symptom:** A newly created application pod could not pull its Docker image.

**Root cause:** The deployment manifest contained an invalid image reference. A SHA-256 digest had been used as though it were a repository name, causing Kubernetes to attempt to pull the image from the wrong registry.

**Resolution:**

1. Inspected pod status and Kubernetes events.
2. Checked the deployment manifest and image reference.
3. Verified that the image existed in Amazon ECR.
4. Corrected the image reference and Jenkins image substitution.
5. Committed the corrected manifest to GitHub.
6. Reran the Jenkins pipeline.
7. Verified that the application pods became healthy.

**Lesson learned:** Kubernetes needs a valid image reference, for example:

`ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY:TAG`

A digest by itself is not a complete registry image reference.

### Issue 2: EKS managed node group provisioning

Earlier node group provisioning attempts encountered node health problems. The infrastructure configuration and provisioning process were reviewed until the EKS cluster and managed node group reached a healthy state.

This troubleshooting highlighted the importance of checking:

- IAM permissions and worker node roles.
- Subnet placement and routing.
- Security group rules.
- Node bootstrap and cluster connectivity.
- EKS node group status and Kubernetes node readiness.

## 12. Security Considerations

- Use EC2 IAM roles for AWS access rather than committing long-lived access keys.
- Never commit AWS credentials, private keys, secret `.env` files, or Terraform state files to GitHub.
- Restrict Jenkins access and secure webhook traffic.
- Apply least-privilege IAM policies.
- Restrict security group ingress to required sources and ports.
- Protect Terraform state because it may contain sensitive infrastructure data.
- Use container image scanning and dependency security checks.
- Remove unused lab resources when the project is no longer needed.

## 13. Project Outcome

The completed lab demonstrates an end-to-end DevOps workflow that combines Terraform-based AWS infrastructure provisioning with Jenkins-driven application delivery.

The project includes:

- Terraform-based infrastructure provisioning.
- EKS cluster and managed node group provisioning.
- IAM permissions for AWS automation and Kubernetes access.
- Amazon ECR image management.
- GitHub webhook-triggered Jenkins pipeline.
- Python application testing and Docker image creation.
- Kubernetes Deployment and Service.
- Horizontal Pod Autoscaler configuration.
- Ingress-based application exposure through an AWS Application Load Balancer.
- Practical troubleshooting and deployment verification.

The project demonstrates how infrastructure provisioning, application delivery, and Kubernetes operations work together in an AWS DevOps environment.

## 14. Future Improvements

- Add HTTPS and a custom domain for application access.
- Introduce separate development and production environments.
- Add container image scanning and automated security checks.
- Add monitoring, dashboards, and alerting.
- Document deployment rollback and recovery procedures.
- Improve Terraform remote-state management and state locking.
- Add automated cleanup procedures for temporary lab resources.
- Review IAM policies and network access for production readiness.

## 15. AWS DevOps Interview Summary

"My project is an end-to-end CI/CD platform for deploying a Python Streamlit application on Amazon EKS.

I used Terraform to provision AWS infrastructure, including networking, IAM resources, ECR, the EKS cluster, add-ons, and the managed node group. I configured Jenkins to check out the code, run tests, build a Docker image, push it to Amazon ECR, and deploy the application to Kubernetes.

GitHub webhooks trigger the pipeline on repository changes. Kubernetes Deployment and Service resources manage the application, HPA is configured for horizontal pod scaling, and Ingress integrates with the AWS Load Balancer Controller to expose the application through an ALB.

I also troubleshot an image-pull failure by examining Kubernetes events and correcting the container image reference. This project helped me develop practical skills in Terraform, AWS IAM, Jenkins, Docker, ECR, EKS, Kubernetes, and CI/CD troubleshooting."



GitHub webhook CI/CD test
