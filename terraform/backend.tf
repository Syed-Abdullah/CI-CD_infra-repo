# =============================================================================
# REMOTE BACKEND — S3 + DynamoDB
# =============================================================================
# By default, Terraform stores its "state" (a JSON snapshot of everything it
# manages) in a local file called terraform.tfstate. That works fine for solo
# projects, but breaks in teams because:
#   - Two people could run `terraform apply` at the same time and corrupt state
#   - If your laptop dies, you lose the state and Terraform "forgets" your infra
#
# A REMOTE BACKEND solves both problems:
#   S3 bucket  → stores the state file in the cloud (durable, versioned)
#   DynamoDB   → provides a "lock" so only one person can modify state at a time
#
# IMPORTANT: The S3 bucket and DynamoDB table must already exist before you
# run `terraform init`. Create them manually or with a separate bootstrap script.
# =============================================================================

terraform {
  backend "s3" {
    # -------------------------------------------------------------------------
    # bucket: The name of the S3 bucket that holds our state file.
    #         S3 bucket names are globally unique across ALL AWS accounts.
    #         CHANGE THIS to your own bucket name.
    # -------------------------------------------------------------------------
    bucket = "cicd-demo-terraform-state-bucket"

    # -------------------------------------------------------------------------
    # key: The path/filename inside the bucket where the state is stored.
    #      Using a folder structure lets you store multiple projects' state
    #      in the same bucket (e.g., "prod/terraform.tfstate").
    # -------------------------------------------------------------------------
    key = "infra-repo/terraform.tfstate"

    # -------------------------------------------------------------------------
    # region: The AWS region where the S3 bucket lives.
    #         This does NOT have to match the region where your EC2s live,
    #         but keeping it the same is simpler.
    # -------------------------------------------------------------------------
    region = "us-east-1"

    # -------------------------------------------------------------------------
    # dynamodb_table: The DynamoDB table used for state locking.
    #                 Terraform writes a "lock" row here before modifying state.
    #                 If another process already holds the lock, Terraform waits.
    #                 The table needs a partition key named "LockID" (String).
    # -------------------------------------------------------------------------
    dynamodb_table = "cicd-demo-terraform-lock-table"

    # -------------------------------------------------------------------------
    # encrypt: Encrypt the state file at rest using AWS-managed keys (SSE-S3).
    #          State files can contain sensitive data (IP addresses, resource
    #          IDs), so encryption is a best practice.
    # -------------------------------------------------------------------------
    encrypt = true
  }
}
