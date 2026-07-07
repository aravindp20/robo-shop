output "state_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket storing Terraform remote state"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of the public subnets"
}

output "private_app_subnet_ids" {
  value       = module.vpc.private_app_subnet_ids
  description = "IDs of the private app subnets"
}

output "private_data_subnet_ids" {
  value       = module.vpc.private_data_subnet_ids
  description = "IDs of the private data subnets"
}
