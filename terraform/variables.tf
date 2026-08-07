# =============================================================================
# INPUT VARIABLES
# =============================================================================
# Variables make our Terraform code reusable. Instead of hardcoding values
# like region or instance type, we define them here with sensible defaults.
# You can override any default by:
#   1. Creating a terraform.tfvars file      (gitignored for safety)
#   2. Passing -var="key=value" on the CLI
#   3. Setting TF_VAR_<name> environment variables
# =============================================================================

# ---------------------------------------------------------------------------
# AWS Region
# ---------------------------------------------------------------------------
# The AWS data-center region where all resources will be created.
# Default: us-east-1 (N. Virginia) — one of the cheapest and most feature-rich.
# ---------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region where all resources will be provisioned"
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------------------------
# EC2 Instance Type
# ---------------------------------------------------------------------------
# This controls the size (CPU/RAM) of both EC2 instances.
#
# Recommended:
#   c7i-flex.large — 2 vCPUs, 4 GB RAM, good price/performance for CI/CD
#   m7i-flex.large — 2 vCPUs, 8 GB RAM, extra headroom for kind clusters
#   t3.small       — 2 vCPUs, 2 GB RAM, minimum fallback (tight but works)
#
# Jenkins + Docker builds and kind's control plane are both memory-hungry,
# so don't go smaller than t3.small.
# ---------------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type for both servers (Jenkins and kind)"
  type        = string
  default     = "t3.small"
}

# ---------------------------------------------------------------------------
# AMI ID
# ---------------------------------------------------------------------------
# The Amazon Machine Image — this is the "disk image" that the EC2 boots from.
# We use Ubuntu 22.04 LTS (Jammy Jellyfish) because:
#   - Long-term support until 2027
#   - Excellent Docker and Kubernetes compatibility
#   - Huge community and documentation
#
# NOTE: AMI IDs are region-specific. The default below is for us-east-1.
#       If you change the region, you MUST also update this AMI ID.
#       Find the right ID: https://cloud-images.ubuntu.com/locator/ec2/
# ---------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS (region-specific)"
  type        = string
  default     = "ami-0e1bed4f06a3b463d" # Ubuntu 22.04 LTS in us-east-1
}

# ---------------------------------------------------------------------------
# Key Pair Name
# ---------------------------------------------------------------------------
# The name of an EXISTING AWS EC2 key pair. This key pair lets you SSH into
# the instances. Terraform does NOT create the key pair — it must already
# exist in your AWS account under EC2 → Key Pairs.
#
# IMPORTANT: Replace the default with YOUR key pair name.
# ---------------------------------------------------------------------------
variable "key_pair_name" {
  description = "Name of an existing AWS EC2 key pair for SSH access"
  type        = string
  default     = "my-ec2-keypair" # <-- CHANGE THIS to your actual key pair name
}

# ---------------------------------------------------------------------------
# Project Name Tag
# ---------------------------------------------------------------------------
# A prefix used in resource names and tags for easy identification.
# Helps you filter resources in the AWS console.
# ---------------------------------------------------------------------------
variable "project_name" {
  description = "Project name used for tagging and naming resources"
  type        = string
  default     = "cicd-demo"
}
