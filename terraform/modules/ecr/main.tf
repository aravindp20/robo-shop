terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Amazon ECR Repositories
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "repo" {
  for_each = toset(var.repository_names)

  name                 = "robot-shop-${var.environment}-${each.value}"
  image_tag_mutability = "IMMUTABLE"

  # Shift-Left Security: Enable scanning on push to detect container CVEs
  image_scanning_configuration {
    scan_on_push = true
  }

  # Compliance: Encrypt images at rest using KMS
  encryption_configuration {
    encryption_type = "KMS"
    # Defaults to the aws/ecr KMS key when no custom key is provided
  }

  tags = {
    Name        = "robot-shop-${var.environment}-${each.value}"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Lifecycle Policy (Prune untagged developer builds to manage storage costs)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each = toset(var.repository_names)

  repository = aws_ecr_repository.repo[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged developer images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
