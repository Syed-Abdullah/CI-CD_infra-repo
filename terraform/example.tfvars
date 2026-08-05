# =============================================================================
# EXAMPLE TERRAFORM VARIABLES FILE
# =============================================================================
# Copy this file to terraform.tfvars and fill in your actual values.
# terraform.tfvars is gitignored to prevent accidental secret leaks.
#
# Usage:
#   cp example.tfvars terraform.tfvars
#   # Edit terraform.tfvars with your values
#   terraform plan
# =============================================================================

aws_region    = "us-east-1"
instance_type = "t3.small"                 # Or "c7i-flex.large" / "m7i-flex.large"
ami_id        = "ami-0e1bed4f06a3b463d"    # Ubuntu 22.04 LTS in us-east-1
key_pair_name = "my-ec2-keypair"           # <-- CHANGE to your existing key pair name
project_name  = "cicd-demo"
