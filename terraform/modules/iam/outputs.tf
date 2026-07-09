output "eks_cluster_role_arn" {
  value       = aws_iam_role.eks_cluster.arn
  description = "The ARN of the EKS Cluster control plane IAM role"
}

output "eks_node_role_arn" {
  value       = aws_iam_role.eks_node.arn
  description = "The ARN of the EKS Node Group IAM role"
}

output "secrets_manager_policy_arn" {
  value       = aws_iam_policy.secrets_manager.arn
  description = "The ARN of the Secrets Manager access policy"
}

