output "state_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket storing Terraform remote state"
}

output "state_kms_key_arn" {
  value       = aws_kms_key.terraform_state.arn
  description = "The ARN of the KMS key used to encrypt the Terraform state bucket"
}

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

output "eks_secrets_irsa_role_arn" {
  value       = module.iam.eks_secrets_irsa_role_arn
  description = "The ARN of the EKS Secrets Manager IRSA IAM role (if OIDC is configured)"
}

