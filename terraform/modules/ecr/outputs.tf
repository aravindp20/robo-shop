output "repository_urls" {
  value       = { for k, v in aws_ecr_repository.repo : k => v.repository_url }
  description = "A map of repository names to their corresponding ECR registry URLs"
}
