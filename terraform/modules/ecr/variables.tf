variable "repository_names" {
  type        = list(string)
  description = "List of ECR repository names to create"
}

variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev)"
}
