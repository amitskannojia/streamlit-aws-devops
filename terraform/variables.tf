variable "aws_region" {
  description = "AWS region for the lab"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short project name used in AWS resource names"
  type        = string
  default     = "streamlit"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "streamlit-eks"
}

variable "node_group_name" {
  description = "EKS managed node group name"
  type        = string
  default     = "streamlit-nodegroup"
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_cidr" {
  description = "Your public IPv4 address in CIDR notation, for example 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be a valid IPv4 CIDR such as 203.0.113.10/32."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.35"
}

variable "instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_nodes" {
  description = "Minimum worker nodes"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum worker nodes"
  type        = number
  default     = 3
}
