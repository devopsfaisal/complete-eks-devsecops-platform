variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "complete-eks-platform"
}

variable "cluster_version" {
  description = "Kubernetes Version"
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Base domain registered on Route 53"
  type        = string
  default     = "faisal.host"
}

variable "subdomain" {
  description = "Subdomain to provision with ACM SSL"
  type        = string
  default     = "eks.faisal.host"
}

variable "node_instance_types" {
  description = "Worker node EC2 instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}
