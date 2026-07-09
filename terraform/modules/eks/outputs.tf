output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "The name of the EKS Cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "The endpoint URL for the EKS Cluster control plane"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.eks.arn
  description = "The ARN of the EKS OIDC Provider"
}

output "oidc_provider_url" {
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
  description = "The issuer URL of the EKS OIDC Provider"
}

output "eks_secrets_irsa_role_arn" {
  value       = aws_iam_role.eks_secrets_irsa.arn
  description = "The ARN of the EKS Secrets Manager IRSA IAM role"
}

