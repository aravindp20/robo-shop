output "eks_cluster_role_arn" {
  value       = aws_iam_role.eks_cluster.arn
  description = "The ARN of the EKS Cluster control plane IAM role"
}

output "eks_node_role_arn" {
  value       = aws_iam_role.eks_node.arn
  description = "The ARN of the EKS Node Group IAM role"
}

output "eks_secrets_irsa_role_arn" {
  value       = length(aws_iam_role.eks_secrets_irsa) > 0 ? aws_iam_role.eks_secrets_irsa[0].arn : null
  description = "The ARN of the EKS Secrets Manager IRSA IAM role, if OIDC was configured"
}
