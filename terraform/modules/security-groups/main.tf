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
# 1. Security Group Definitions
# ─────────────────────────────────────────────────────────────────────────────

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = "robot-shop-alb-sg"
  description = "Security Group for the Application Load Balancer (public facing)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "robot-shop-alb-sg"
  }
}

# EKS Nodes Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "robot-shop-eks-nodes-sg"
  description = "Security Group for EKS worker nodes in private subnets"
  vpc_id      = var.vpc_id

  tags = {
    Name = "robot-shop-eks-nodes-sg"
  }
}

# RDS MySQL Security Group
resource "aws_security_group" "rds" {
  name        = "robot-shop-rds-sg"
  description = "Security Group for RDS MySQL database"
  vpc_id      = var.vpc_id

  tags = {
    Name = "robot-shop-rds-sg"
  }
}

# ElastiCache Redis Security Group
resource "aws_security_group" "elasticache" {
  name        = "robot-shop-elasticache-sg"
  description = "Security Group for ElastiCache Redis cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name = "robot-shop-elasticache-sg"
  }
}

# Amazon MQ RabbitMQ Security Group
resource "aws_security_group" "mq" {
  name        = "robot-shop-mq-sg"
  description = "Security Group for Amazon MQ RabbitMQ broker"
  vpc_id      = var.vpc_id

  tags = {
    Name = "robot-shop-mq-sg"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. ALB Security Group Rules
# ─────────────────────────────────────────────────────────────────────────────

# Ingress: Allow HTTP from internet
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "Allow HTTP from internet"
}

# Ingress: Allow HTTPS from internet
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS from internet"
}

# Egress: Allow ALB to talk to EKS Nodes on all ports (supports both NodePort and IP targets)
resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
  description                  = "Allow outbound traffic to EKS worker nodes"
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. EKS Nodes Security Group Rules
# ─────────────────────────────────────────────────────────────────────────────

# Ingress: Allow traffic from ALB Security Group
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "-1"
  description                  = "Allow inbound traffic from ALB"
}

# Ingress: Allow node-to-node (self-reference) communication
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
  description                  = "Allow communication between EKS worker nodes"
}

# Egress: Allow nodes to access the internet (for ECR, public packages, etc. via NAT GW)
resource "aws_vpc_security_group_egress_rule" "nodes_to_internet" {
  security_group_id = aws_security_group.eks_nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic from EKS worker nodes"
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. RDS Security Group Rules
# ─────────────────────────────────────────────────────────────────────────────

# Ingress: Allow MySQL traffic from EKS nodes
resource "aws_vpc_security_group_ingress_rule" "rds_from_nodes" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "Allow MySQL traffic from EKS worker nodes"
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. ElastiCache Security Group Rules
# ─────────────────────────────────────────────────────────────────────────────

# Ingress: Allow Redis traffic from EKS nodes
resource "aws_vpc_security_group_ingress_rule" "elasticache_from_nodes" {
  security_group_id            = aws_security_group.elasticache.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  description                  = "Allow Redis traffic from EKS worker nodes"
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. Amazon MQ (RabbitMQ) Security Group Rules
# ─────────────────────────────────────────────────────────────────────────────

# Ingress: Allow AMQP (non-TLS) traffic from EKS nodes
resource "aws_vpc_security_group_ingress_rule" "mq_amqp_from_nodes" {
  security_group_id            = aws_security_group.mq.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 5672
  to_port                      = 5672
  description                  = "Allow AMQP traffic from EKS worker nodes"
}

# Ingress: Allow AMQPS (TLS) traffic from EKS nodes
resource "aws_vpc_security_group_ingress_rule" "mq_amqps_from_nodes" {
  security_group_id            = aws_security_group.mq.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 5671
  to_port                      = 5671
  description                  = "Allow AMQPS traffic from EKS worker nodes"
}

# Ingress: Allow RabbitMQ Management console traffic (non-TLS) from EKS nodes
resource "aws_vpc_security_group_ingress_rule" "mq_mgmt_from_nodes" {
  security_group_id            = aws_security_group.mq.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 15672
  to_port                      = 15672
  description                  = "Allow RabbitMQ Web Management traffic from EKS worker nodes"
}

# Ingress: Allow RabbitMQ Management console traffic (TLS) from EKS nodes
resource "aws_vpc_security_group_ingress_rule" "mq_mgmts_from_nodes" {
  security_group_id            = aws_security_group.mq.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 15671
  to_port                      = 15671
  description                  = "Allow RabbitMQ Web Management TLS traffic from EKS worker nodes"
}
