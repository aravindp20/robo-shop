
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of the public subnets"
}

output "private_app_subnet_ids" {
  value       = module.vpc.private_app_subnet_ids
  description = "IDs of the private app subnets"
}

output "private_data_subnet_ids" {
  value       = module.vpc.private_data_subnet_ids
  description = "IDs of the private data subnets"
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Groups Outputs
# ─────────────────────────────────────────────────────────────────────────────
output "alb_sg_id" {
  value       = module.security_groups.alb_sg_id
  description = "The ID of the ALB security group"
}

output "eks_nodes_sg_id" {
  value       = module.security_groups.eks_nodes_sg_id
  description = "The ID of the EKS worker nodes security group"
}

output "rds_sg_id" {
  value       = module.security_groups.rds_sg_id
  description = "The ID of the RDS security group"
}

output "redis_sg_id" {
  value       = module.security_groups.redis_sg_id
  description = "The ID of the ElastiCache security group"
}

output "mq_sg_id" {
  value       = module.security_groups.mq_sg_id
  description = "The ID of the Amazon MQ security group"
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM Roles Outputs
# ─────────────────────────────────────────────────────────────────────────────
output "eks_cluster_role_arn" {
  value       = module.iam.eks_cluster_role_arn
  description = "The ARN of the EKS Cluster control plane IAM role"
}

output "eks_node_role_arn" {
  value       = module.iam.eks_node_role_arn
  description = "The ARN of the EKS Node Group IAM role"
}

output "secrets_manager_policy_arn" {
  value       = module.iam.secrets_manager_policy_arn
  description = "The ARN of the Secrets Manager access policy"
}

# ─────────────────────────────────────────────────────────────────────────────
# ECR Outputs
# ─────────────────────────────────────────────────────────────────────────────
output "ecr_repository_urls" {
  value       = module.ecr.repository_urls
  description = "A map of repository names to their corresponding ECR registry URLs"
}

# ─────────────────────────────────────────────────────────────────────────────
# EKS Outputs
# ─────────────────────────────────────────────────────────────────────────────
output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS Cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint URL for the EKS Cluster control plane"
}

output "eks_cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "The ARN of the EKS OIDC Provider"
}

output "eks_secrets_irsa_role_arn" {
  value       = module.eks.eks_secrets_irsa_role_arn
  description = "The ARN of the EKS Secrets Manager IRSA IAM role"
}


