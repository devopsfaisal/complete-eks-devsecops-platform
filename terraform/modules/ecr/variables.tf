variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "complete-eks-demo-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}
