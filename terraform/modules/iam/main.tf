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
# 1. EKS Cluster IAM Role (Control Plane)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "eks_cluster" {
  name = "robot-shop-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "robot-shop-${var.environment}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. EKS Node Group IAM Role (Worker Nodes)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "eks_node" {
  name = "robot-shop-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "robot-shop-${var.environment}-eks-node-role"
  }
}

# Required policies for EKS worker nodes to function and join cluster
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

# Allows secure instance management and session access via AWS SSM without open SSH ports (CKV_AWS_135)
resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node.name
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Secrets Manager Scoped Policy (Least Privilege)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_iam_policy" "secrets_manager" {
  name        = "robot-shop-${var.environment}-secrets-manager-policy"
  description = "Enables EKS workloads to retrieve application secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        # Scope restricted to secrets prefixed with 'robot-shop/' (SOC2/Least privilege compliance)
        Resource = "arn:aws:secretsmanager:*:*:secret:robot-shop/*"
      }
    ]
  })

  tags = {
    Name = "robot-shop-${var.environment}-secrets-manager-policy"
  }
}

# Attach to worker node role as a secondary fallback
resource "aws_iam_role_policy_attachment" "node_secrets_manager" {
  policy_arn = aws_iam_policy.secrets_manager.arn
  role       = aws_iam_role.eks_node.name
}


