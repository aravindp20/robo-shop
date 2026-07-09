variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}


variable "subnet_ids" {
  type        = list(string)
  description = "The list of subnet IDs where the EKS worker nodes will be deployed (should be private subnets)"
}

variable "cluster_role_arn" {
  type        = string
  description = "The ARN of the IAM role assumed by the EKS control plane"
}

variable "node_role_arn" {
  type        = string
  description = "The ARN of the IAM role assumed by EKS worker nodes"
}

variable "eks_nodes_sg_id" {
  type        = string
  description = "The custom security group ID for EKS worker nodes"
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types to use for EKS worker nodes"
  default     = ["t3.medium"]
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 5
}

variable "secrets_manager_policy_arn" {
  type        = string
  description = "The ARN of the Secrets Manager access policy"
}

