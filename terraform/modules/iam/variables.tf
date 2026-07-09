variable "environment" {
  type        = string
  description = "The target environment (e.g., dev, prod)"
}

variable "oidc_provider_arn" {
  type        = string
  description = "The ARN of the OIDC provider for EKS (optional, used for IRSA)"
  default     = ""
}

variable "oidc_provider_url" {
  type        = string
  description = "The OIDC provider URL for EKS (optional, used for IRSA)"
  default     = ""
}
