# ─────────────────────────────────────────────────────────────────────────────
# BOOTSTRAP INSTRUCTIONS — READ BEFORE RUNNING
# ─────────────────────────────────────────────────────────────────────────────
#
# PHASE 1 — First-time setup (S3 bucket does not exist yet):
#   1. Keep the terraform{} backend block COMMENTED OUT below.
#   2. Run: terraform init
#   3. Run: terraform apply -target=aws_s3_bucket.terraform_state
#            -target=aws_s3_bucket_versioning.state_versioning
#            -target=aws_s3_bucket_public_access_block.state_public_block
#            -target=aws_kms_key.terraform_state
#   4. Confirm the bucket name in AWS matches 'state_bucket_name' in terraform.tfvars.
#
# PHASE 2 — Migrate state to S3 (bucket now exists):
#   1. Uncomment the terraform{} backend block below.
#   2. Update 'bucket' to exactly match 'state_bucket_name' in terraform.tfvars.
#   3. Run: terraform init -migrate-state
#   4. All future plans/applies (including CI/CD) will now use the S3 backend.
#
# ─────────────────────────────────────────────────────────────────────────────

# terraform {
#   backend "s3" {
#     bucket       = "robot-shop-prod-tfstate-bucket-unique-suffix" # Must match state_bucket_name in tfvars
#     key          = "prod/terraform.tfstate"
#     region       = "ap-south-1"
#     encrypt      = true
#     use_lockfile = true # Enables native S3 locking (requires Terraform 1.10+)
#   }
# }

# ── PHASE 2 ACTIVE ── Bucket exists. Uncomment the block below and run:
#   terraform init -migrate-state
terraform {
  backend "s3" {
    bucket       = "robot-shop-prod-tfstate-bucket-unique-suffix" # Must match state_bucket_name in tfvars
    key          = "prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # Enables native S3 locking (requires Terraform 1.10+)
  }
}

