# ─────────────────────────────────────────────────────────────────────────────
# S3 Bucket — Terraform Remote State
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.state_bucket_name
  force_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

# Enable Versioning for State Recovery and Native Locking integrity
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all Public Access to state data
resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── CKV_AWS_145: KMS encryption (stronger than AES256) ─────────────────────
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for robot-shop Terraform state bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "robot-shop-tf-state-kms"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/robot-shop-terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true # Reduces KMS API call costs
  }
}

# ─── CKV_AWS_18: Access logging for the state bucket ────────────────────────
resource "aws_s3_bucket" "state_access_logs" {
  bucket        = "${var.state_bucket_name}-access-logs"
  force_destroy = true

  tags = {
    Name = "robot-shop-tf-state-access-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "state_access_logs" {
  bucket                  = aws_s3_bucket.state_access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "state_logging" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.state_access_logs.id
  target_prefix = "s3-access-logs/"
}

# ─── CKV2_AWS_61: Lifecycle configuration ───────────────────────────────────
# Expire old non-current state versions after 90 days to manage storage costs
resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  # Must have versioning enabled first
  depends_on = [aws_s3_bucket_versioning.state_versioning]

  rule {
    id     = "expire-noncurrent-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

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

  instance_types = ["t3.small"]
  desired_size   = 2
  min_size       = 2
  max_size       = 5
}


