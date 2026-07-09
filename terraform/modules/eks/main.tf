terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. CloudWatch Log Group for EKS Audit & Control Plane Logs
#    Explicitly managing this prevents infinite logging retention charges (SOC2 compliance)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name = "/aws/eks/${var.cluster_name}/cluster"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. KMS Key for EKS Secret Envelope Encryption (Data-At-Rest Compliance)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secret envelope encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-kms-key"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks-${var.cluster_name}"
  target_key_id = aws_kms_key.eks.key_id
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. EKS Cluster Control Plane
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = "1.31" # Latest production-ready version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true # Nodes write to EKS API via private subnets
    endpoint_public_access  = true # Allows kubectl management (restricted security recommended in prod)
  }

  # Enable envelope encryption of Kubernetes secrets
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  # Stream logs to CloudWatch
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Ensure Log Group exists before enabling cluster logging
  depends_on = [aws_cloudwatch_log_group.eks]

  tags = {
    Name = var.cluster_name
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Managed Worker Node Group & Launch Template
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_launch_template" "eks_nodes" {
  name_prefix            = "${var.cluster_name}-node-template-"
  description            = "Custom launch template for EKS worker nodes"
  update_default_version = true

  # Attach our custom security group for DB/Queue peer connections
  vpc_security_group_ids = [var.eks_nodes_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-worker-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  instance_types = var.instance_types
  capacity_type  = "ON_DEMAND"

  launch_template {
    name    = aws_launch_template.eks_nodes.name
    version = aws_launch_template.eks_nodes.default_version
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size] # Allow autoscalers (HPA/Karpenter) to scale
  }

  tags = {
    Name = "${var.cluster_name}-node-group"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. OIDC Federated Provider (Required for IRSA / Pod Level Permissions)
# ─────────────────────────────────────────────────────────────────────────────

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. IAM Role for EKS Service Accounts (IRSA)
#    Enables pods using 'robot-shop-secrets-sa' to assume this role via OIDC
# ─────────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "eks_oidc_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      # Limits access strictly to a dedicated service account name inside any namespace
      values = ["system:serviceaccount:*:robot-shop-secrets-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_secrets_irsa" {
  name               = "robot-shop-${var.cluster_name}-secrets-irsa"
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume.json

  tags = {
    Name = "robot-shop-${var.cluster_name}-secrets-irsa"
  }
}

resource "aws_iam_role_policy_attachment" "irsa_secrets_manager" {
  policy_arn = var.secrets_manager_policy_arn
  role       = aws_iam_role.eks_secrets_irsa.name
}

