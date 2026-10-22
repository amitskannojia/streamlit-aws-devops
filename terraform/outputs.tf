output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_node_group_name" {
  description = "Managed node group name"
  value       = aws_eks_node_group.main.node_group_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "jenkins_role_arn" {
  description = "IAM role to attach to the Jenkins EC2 instance"
  value       = aws_iam_role.jenkins.arn
}

output "jenkins_instance_profile_name" {
  description = "IAM instance profile name for Jenkins"
  value       = aws_iam_instance_profile.jenkins.name
}

output "jenkins_access_entry" {
  description = "Jenkins EKS access entry principal"
  value       = aws_eks_access_entry.jenkins.principal_arn
}
