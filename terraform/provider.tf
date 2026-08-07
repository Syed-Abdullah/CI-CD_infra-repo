# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
# This file tells Terraform:
#   1. Which cloud provider we're using (AWS)
#   2. Which region to create resources in (us-east-1, N. Virginia)
#   3. Which version of the AWS provider plugin to download
#
# Think of a "provider" as a translator — Terraform speaks its own language
# (HCL), and the provider translates that into AWS API calls.
# =============================================================================

terraform {
  # ---------------------------------------------------------------------------
  # Required Providers Block
  # ---------------------------------------------------------------------------
  # This pins the AWS provider to version 5.x. Pinning prevents surprise
  # breaking changes when HashiCorp releases a new major version.
  # ---------------------------------------------------------------------------
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # We require Terraform CLI version 1.5 or newer
  required_version = ">= 1.5.0"
}

# ---------------------------------------------------------------------------
# AWS Provider
# ---------------------------------------------------------------------------
# region: The AWS data-center region where ALL resources will be created.
#         us-east-1 (N. Virginia) is the most commonly used region.
#
# Credentials are NOT hardcoded here — Terraform automatically reads them
# from environment variables (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)
# or from the AWS CLI profile (~/.aws/credentials).
# ---------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}
