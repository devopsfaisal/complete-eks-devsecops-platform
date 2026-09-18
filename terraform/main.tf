# 1. Networking Layer: VPC, Subnets, NAT Gateway, IGW
module "vpc" {
  source = "./modules/vpc"

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# 2. Kubernetes Compute: EKS 1.36 Cluster, Node Groups, OIDC Provider, KMS
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_types     = var.node_instance_types
  desired_size       = var.desired_nodes
  environment        = var.environment
}

# 3. Artifact Registry: AWS ECR with Scan-On-Push & 10-Image Retention Policy
module "ecr" {
  source = "./modules/ecr"

  repository_name = "complete-eks-demo-app"
  environment     = var.environment
}

# 4. DNS & SSL: Route 53 & ACM Certificate with Auto-Validation
module "route53_acm" {
  source = "./modules/route53-acm"

  domain_name = var.domain_name
  subdomain   = var.subdomain
  environment = var.environment
}

# 5. In-Cluster Addons via Helm: Metrics Server, AWS Load Balancer Controller, ArgoCD
module "cluster_addons" {
  source = "./modules/cluster-addons"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  vpc_id                 = module.vpc.vpc_id
  environment            = var.environment

  depends_on = [module.eks]
}
