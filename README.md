# Streamlit AWS DevOps Automation Platform

## 1. Project Overview

This project demonstrates an end-to-end DevOps workflow for deploying a Streamlit Python application on Amazon EKS using a Jenkins CI/CD pipeline.

The pipeline automates source code checkout, application testing, Docker image creation, pushing images to Amazon ECR, and deploying the application to Kubernetes. GitHub webhooks trigger Jenkins when new code is pushed.

Terraform configuration is included for infrastructure as code. The EKS cluster and managed node group for this lab were created through the AWS Console to work around node group provisioning issues. Terraform validation confirms the configuration syntax is valid; actual Terraform-managed resources should be documented according to the resources tracked in Terraform state.

## 2. Project Objectives

- Automate application delivery using Jenkins.
- Trigger builds using GitHub webhooks.
- Run automated Python tests before deployment.
- Containerize the Streamlit application using Docker.
- Store versioned images in Amazon ECR.
- Deploy the application to Amazon EKS.
- Expose the application using Kubernetes Service, Ingress, and AWS Application Load Balancer.
- Configure Kubernetes Horizontal Pod Autoscaler (HPA).
- Maintain Terraform configuration for infrastructure as code.
- Practice troubleshooting CI/CD and Kubernetes deployment failures.

## 3. Architecture

```text
Developer
   |
   | Git Push
   v
GitHub Repository
   |
   | Webhook
   v
Jenkins CI/CD Pipeline
   |
   +--> Checkout Source Code
   |
   +--> Install Dependencies and Run Tests
   |
   +--> Build Docker Image
   |
   +--> Push Image to Amazon ECR
   |
   +--> Update Kubernetes Image Reference
   |
   +--> Deploy to Amazon EKS
             |
             v
       Kubernetes Deployment
             |
             +--> Streamlit Pods
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
       User's Web Browser
```

## 4. Technologies Used

| Technology | Purpose |
|---|---|
| AWS EC2 | Jenkins server and lab administration |
| AWS IAM | Permissions for AWS services |
| Amazon VPC | Network infrastructure |
| Terraform | Infrastructure configuration and validation |
| Git and GitHub | Source code management |
| GitHub Webhooks | Automatic build triggers |
| Jenkins | CI/CD automation |
| Python and Streamlit | Application and user interface |
| Pytest | Automated tests |
| Docker | Application containerization |
| Amazon ECR | Docker image registry |
| Amazon EKS | Managed Kubernetes control plane |
| Kubernetes | Application deployment and service management |
| Kubernetes HPA | Horizontal pod autoscaling |
| AWS Application Load Balancer | External application access |
| kubectl | Kubernetes administration |

## 5. Repository Structure

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

The Terraform directory lists the intended configuration layout. Verify the actual files and Terraform state before claiming that every listed AWS resource is managed by Terraform.

## 6. CI/CD Workflow

### Stage 1: Checkout

Jenkins checks out the source code from the configured GitHub repository and branch.

### Stage 2: Test

Jenkins creates a Python virtual environment, installs the application dependencies and pytest, and executes the tests under `tests/`.

The pipeline stops if the tests fail.

### Stage 3: Verify AWS and EKS

The pipeline checks the AWS identity, confirms the EKS cluster is available, configures Kubernetes access for the Jenkins build, and checks cluster nodes.

### Stage 4: Build and Push to ECR

Jenkins obtains the AWS account ID, authenticates Docker to Amazon ECR, builds the application image, and pushes it to the `streamlit-app` repository.

Images are tagged using the Jenkins build number.

### Stage 5: Deploy to EKS

The pipeline generates a deployment manifest with the actual ECR image URI, then applies the namespace, deployment, service, HPA and ingress resources.

Jenkins waits for the application rollout to complete.

## 7. Kubernetes Configuration

- **Namespace:** `streamlit`
- **Deployment:** `streamlit-app`
- **Container:** `streamlit`
- **Service:** `streamlit-service`
- **Container port:** `8501`
- **Service port:** `80`
- **Desired application replicas:** `2`
- **HPA minimum replicas:** `2`
- **HPA maximum replicas:** `5`
- **HPA CPU target:** `50%`
- **Ingress:** `streamlit-ingress`
- **Ingress controller:** AWS Load Balancer Controller
- **External access:** AWS Application Load Balancer

The HPA requires working Kubernetes metrics. Actual scaling depends on resource utilization and available capacity.

## 8. Deployment Verification

Run the following commands on the lab EC2 instance.

### Check the Jenkins-triggered Kubernetes deployment

```bash
sudo -u jenkins kubectl --kubeconfig=/var/lib/jenkins/.kube/config get deployments,pods,services -n streamlit
```

### Check Ingress and ALB hostname

```bash
sudo -u jenkins kubectl --kubeconfig=/var/lib/jenkins/.kube/config get ingress -n streamlit
```

### Check autoscaler status

```bash
sudo -u jenkins kubectl --kubeconfig=/var/lib/jenkins/.kube/config get hpa -n streamlit
```

### Check pod resource metrics

```bash
sudo -u jenkins kubectl --kubeconfig=/var/lib/jenkins/.kube/config top pods -n streamlit
```

### Check ECR images

```bash
aws ecr describe-images --region ap-south-1 --repository-name streamlit-app --output table
```

### Validate Terraform configuration

```bash
cd /root/streamlit-aws-devops/terraform
terraform validate
```

Terraform validation checks the configuration. It does not prove that infrastructure has been created, that a Terraform state matches the live AWS environment, or that an application deployment is healthy.

## 9. Troubleshooting Experience

### Issue: Kubernetes pod entered `ErrImagePull`

**Symptom:** The newly created pod could not pull its container image.

**Root cause:** The deployment manifest contained a SHA-256 image digest as if it were an image repository name. Kubernetes attempted to pull it from Docker Hub instead of using the Amazon ECR repository URI.

**Resolution:**

1. Inspected the pod status and Kubernetes events.
2. Checked the deployment manifest and Git-tracked version.
3. Verified that the image existed in Amazon ECR.
4. Corrected the deployment manifest to use the `REPLACE_WITH_ECR_IMAGE` placeholder.
5. Ensured Jenkins substituted the placeholder with the tagged ECR image URI before applying the deployment.
6. Committed and pushed the fix to GitHub.
7. Reran the Jenkins pipeline and verified the deployment.

**Lesson learned:** Kubernetes container images must use a valid image reference, such as `ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY:TAG`. A local image digest alone is not a registry image URI.

## 10. Security Considerations

- Prefer an EC2 IAM role for AWS access instead of storing long-lived access keys in source code.
- Never commit AWS credentials, `.env` secrets or Terraform state files to GitHub.
- Restrict Jenkins access and use HTTPS for production webhook traffic.
- Apply least-privilege IAM policies and restrict security group rules.
- Protect Terraform state because it can contain sensitive infrastructure data.
- Monitor AWS resources and remove unused lab resources to control costs.

## 11. Project Outcome

The lab demonstrates a working Jenkins pipeline for testing, containerizing, publishing and deploying a Streamlit application on Amazon EKS. It also demonstrates GitHub-triggered automation, ECR image management, Kubernetes deployment and service exposure through an AWS load balancer.

Terraform configuration was validated, while the EKS cluster and managed node group were created through the AWS Console for this lab. The exact ownership of other infrastructure should be confirmed against Terraform state and the AWS environment.

## 12. Future Improvements

- Manage the complete network infrastructure through Terraform state.
- Automate EKS provisioning using a tested, reproducible infrastructure workflow.
- Secure Jenkins with HTTPS and restricted network access.
- Add image vulnerability scanning and dependency security checks.
- Add monitoring and alerting using CloudWatch, Prometheus and Grafana.
- Add deployment rollback procedures and release approvals.
- Use separate development and production environments.







# AWS DevOps Project — Interview Preparation

## A. Project Introduction (60–90 seconds)

“My project is an end-to-end CI/CD automation platform for a Streamlit Python application deployed on Amazon EKS.

The main objective was to automate the application delivery process from source code commit to Kubernetes deployment.

I used Git and GitHub for source code management, GitHub webhooks to trigger Jenkins, and Jenkins Declarative Pipeline to automate checkout, testing, Docker image creation, and pushing images to Amazon ECR.

For deployment, I used Amazon EKS and Kubernetes resources, including Deployment, Service, HPA and Ingress. The application is exposed externally through an AWS Application Load Balancer using the AWS Load Balancer Controller.

I also maintained Terraform configuration for infrastructure as code and validated it using `terraform validate`. In this lab, I created the EKS cluster and managed node group through the AWS Console because I encountered node group provisioning issues with the earlier Terraform approach.

During troubleshooting, I resolved an image-pull failure caused by an invalid Kubernetes image reference. After correcting the deployment manifest and rerunning the pipeline, the build succeeded.

This project helped me understand CI/CD automation, AWS permissions, containerization, Kubernetes deployment and practical troubleshooting.”

## B. Explain the Architecture

**1. What happens when a developer pushes code?**

A developer pushes a commit to GitHub. The GitHub webhook sends a notification to Jenkins, which starts the configured pipeline.

**2. What does Jenkins do?**

Jenkins checks out the repository, installs dependencies, runs automated tests, builds a Docker image, authenticates to Amazon ECR, pushes the image, and deploys the updated manifest to EKS.

**3. Why do you use Amazon ECR?**

ECR is the container image registry. It stores the versioned Docker images that Kubernetes worker nodes need to pull when starting application pods.

**4. Why Amazon EKS?**

EKS provides a managed Kubernetes control plane. Kubernetes manages application replicas, pod recovery, service discovery and deployment rollouts.

**5. How does the user access the application?**

The AWS Load Balancer Controller provisions or manages an Application Load Balancer based on the Kubernetes Ingress. The ALB routes HTTP traffic to the Kubernetes Service, which forwards requests to the Streamlit pods on port 8501.

**6. What is Terraform used for?**

Terraform defines infrastructure declaratively. In this lab, the configuration was validated, while the EKS cluster and managed node group were created through the AWS Console. I would check Terraform state and resource ownership before claiming that a resource is fully managed by Terraform.

## C. Common AWS DevOps Interview Questions and Answers

### Q1. What is CI/CD?

CI stands for Continuous Integration: integrating changes and running automated checks frequently. CD can mean Continuous Delivery or Continuous Deployment: automating the preparation or release of software changes. My pipeline automates testing, image publishing and deployment.

### Q2. What is the difference between Docker and Kubernetes?

Docker builds and runs containers. Kubernetes orchestrates containers across a cluster, managing replicas, networking, rollouts and recovery.

### Q3. What is a Docker image?

A Docker image is a packaged application and its runtime dependencies. Containers are created from images.

### Q4. What is the difference between ECR and EKS?

Amazon ECR stores container images. Amazon EKS runs and manages the Kubernetes environment where containers are deployed.

### Q5. What is a Kubernetes Deployment?

A Deployment maintains the desired number of application replicas and manages rolling updates and replacement of failed pods.

### Q6. What is a Kubernetes Service?

A Service provides a stable network endpoint for a group of pods. My application uses a ClusterIP Service on port 80 that forwards traffic to container port 8501.

### Q7. What is an Ingress?

An Ingress defines HTTP or HTTPS routing rules into a Kubernetes cluster. With the AWS Load Balancer Controller, the Ingress configuration can provision an AWS ALB.

### Q8. What is HPA?

Horizontal Pod Autoscaler adjusts the number of pod replicas based on configured metrics. In my lab, the target configuration is a minimum of 2 replicas, a maximum of 5, and a CPU utilization target of 50%.

HPA needs a working metrics source and sufficient cluster capacity to scale successfully.

### Q9. What is the difference between HPA and Cluster Autoscaler?

HPA changes the number of pods. Cluster Autoscaler changes the number of worker nodes when configured to do so and when pending pods require additional capacity. They solve different scaling problems.

### Q10. Why use Terraform?

Terraform makes infrastructure definitions repeatable, reviewable and version-controlled. Its plan and state mechanisms help manage infrastructure changes. `terraform validate` checks configuration validity but does not prove that resources are deployed or healthy.

### Q11. How does Jenkins authenticate to AWS?

In this lab, Jenkins uses the EC2 instance's IAM role rather than storing AWS access keys in the repository. IAM permissions determine which AWS actions the role can perform.

### Q12. What is a GitHub webhook?

A webhook sends an HTTP notification when an event, such as a push, occurs in GitHub. Jenkins receives the notification and triggers the configured job.

### Q13. What is the purpose of a Jenkinsfile?

A Jenkinsfile stores the pipeline definition as code in the source repository. It makes the build and deployment process version-controlled and reviewable.

### Q14. What happens if a Jenkins pipeline stage fails?

The pipeline reports a failure and normally does not proceed to subsequent stages. I inspect Console Output, identify the first meaningful error, determine the failing stage, fix the underlying cause, and rerun the pipeline.

### Q15. How would you troubleshoot a pod in `ImagePullBackOff`?

I would inspect the pod events using `kubectl describe pod`, verify the image reference, confirm the image exists in ECR, and check node-side ECR permissions and network connectivity. I would correct the image URI or permissions based on the evidence.

## D. Explain the Actual Error You Fixed

**Interviewer:** Tell me about a deployment issue you faced.

**Answer:**

“After a Jenkins build, the new Kubernetes pod entered `ErrImagePull`. I inspected the pod events and found that Kubernetes was trying to pull a value beginning with `sha256:` from Docker Hub.

I then checked the deployment manifest and discovered that the image field contained a digest as though it were a repository name. The Jenkins pipeline was designed to replace the `REPLACE_WITH_ECR_IMAGE` placeholder, but the source manifest had been changed incorrectly.

I restored the placeholder, verified the ECR repository and pipeline substitution logic, committed the correction to GitHub, and ran the pipeline again. The build succeeded and I verified the deployment afterward.

The main lesson was to inspect the rendered Kubernetes image reference and pod events rather than repeatedly rebuilding the image without checking the deployment configuration.”

## E. Additional Troubleshooting Questions

### Q16. What if Jenkins cannot connect to EKS?

I would check the Jenkins EC2 IAM role, `aws sts get-caller-identity`, `aws eks describe-cluster`, the kubeconfig context, EKS access entries or authentication configuration, Kubernetes authorization, and network access to the EKS endpoint.

### Q17. What if the ALB hostname is missing?

I would inspect the Ingress and its events, check the AWS Load Balancer Controller pods and logs, validate subnet tags and ALB-related IAM permissions, and check security group and subnet configuration.

### Q18. What if HPA displays `<unknown>`?

I would check whether the metrics API is available, inspect the Metrics Server service and endpoints, run `kubectl top pods`, and confirm that containers have CPU resource requests configured.

### Q19. Why did you create the EKS node group through the console?

“In this lab, the earlier Terraform-based node group provisioning attempts failed because the nodes did not become healthy. I used the AWS Console to get the managed node group working and continue the CI/CD lab. I still need to ensure the final infrastructure can be reproduced consistently through Terraform before considering the infrastructure-as-code portion fully automated.”

### Q20. How would you improve this project for production?

I would use HTTPS, restrict Jenkins access, apply least-privilege IAM policies, scan container images, manage secrets securely, use separate environments, automate infrastructure with Terraform state management, introduce monitoring and alerting, and document rollback procedures.

## F. Final Interview Summary

“My project demonstrates how source control, automated testing, container image management, Kubernetes deployment and AWS networking fit together in a CI/CD workflow. I can explain the pipeline stages, validate deployments using Kubernetes commands, and troubleshoot problems using Jenkins logs, pod events and AWS permissions. I also understand which infrastructure was created manually and why Terraform validation alone is not proof of a fully automated infrastructure deployment.”


## CI/CD Verification

GitHub webhook and Jenkins pipeline verification performed in the AWS DevOps lab.
