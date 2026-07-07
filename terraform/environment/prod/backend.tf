# Phase 1: Keep this block commented out during the first 'terraform apply'
# Phase 2: Uncomment this block and run 'terraform init -migrate-state' to migrate local state to S3

terraform {
  backend "s3" {
    bucket       = "robot-shop-prod-tfstate-bucket-unique-suffix" # Must match state_bucket_name in tfvars
    key          = "prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # Enables native S3 locking (requires Terraform 1.10+)
  }
}
