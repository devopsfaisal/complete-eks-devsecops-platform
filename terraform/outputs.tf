output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = module.ecr.repository_url
}

output "acm_certificate_arn" {
  description = "ACM SSL/TLS Certificate ARN"
  value       = module.route53_acm.certificate_arn
}

output "public_app_url" {
  description = "Public Application URL with HTTPS"
  value       = "https://${module.route53_acm.subdomain}"
}

output "kubeconfig_command" {
  description = "Command to configure kubectl on local machine"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
