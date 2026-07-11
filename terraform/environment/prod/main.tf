# ─────────────────────────────────────────────────────────────────────────────
# VPC Module
# ─────────────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  availability_zones        = var.availability_zones
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Groups Module
# ─────────────────────────────────────────────────────────────────────────────
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id = module.vpc.vpc_id
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM Roles Module
# ─────────────────────────────────────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  environment = "prod"
}

# ─────────────────────────────────────────────────────────────────────────────
# ECR Repositories Module
# ─────────────────────────────────────────────────────────────────────────────
module "ecr" {
  source      = "../../modules/ecr"
  environment = "prod"

  repository_names = [
    "web",
    "cart",
    "catalogue",
    "user",
    "payment",
    "shipping",
    "ratings",
    "dispatch",
    "load-gen"
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# EKS Cluster Module
# ─────────────────────────────────────────────────────────────────────────────
module "eks" {
  source = "../../modules/eks"

  cluster_name               = "robot-shop-prod"
  subnet_ids                 = module.vpc.private_app_subnet_ids
  cluster_role_arn           = module.iam.eks_cluster_role_arn
  node_role_arn              = module.iam.eks_node_role_arn
  eks_nodes_sg_id            = module.security_groups.eks_nodes_sg_id
  secrets_manager_policy_arn = module.iam.secrets_manager_policy_arn
  instance_types             = ["t3.small"]
  desired_size               = 2
  min_size                   = 2
  max_size                   = 5

}


