# =============================================================================
# EC2 INSTANCES + ELASTIC IPs
# =============================================================================
# This file creates the two virtual servers (EC2 instances) and attaches a
# static public IP (Elastic IP) to each one.
#
# Key concepts:
#   EC2 Instance — a virtual machine running in AWS. You choose its size
#                  (instance_type), operating system (AMI), and firewall (SG).
#
#   Elastic IP (EIP) — a STATIC public IPv4 address that you own. Without an
#                       EIP, your instance gets a random public IP that changes
#                       every time you stop/start it. An EIP stays the same,
#                       which is critical because:
#                         - Ansible needs a stable IP in its inventory
#                         - Jenkins needs a stable URL for GitHub webhooks
#                         - You need a stable address to visit the app
#
#   EIP Association — the "glue" that attaches an EIP to an EC2 instance.
#                     This is a separate resource so Terraform can manage the
#                     lifecycle independently.
# =============================================================================


# =============================================================================
# EC2 Instance #1: Jenkins Server
# =============================================================================
# Purpose:
#   - Runs Jenkins (CI/CD automation server)
#   - Runs Docker (Jenkins builds Docker images as part of the pipeline)
#   - This is the "brain" of our CI/CD pipeline
#
# After provisioning, Ansible will install Jenkins + Docker on this server.
# =============================================================================
resource "aws_instance" "jenkins_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # Root EBS volume — the "hard drive" of the instance.
  # 20 GB is enough for Ubuntu + Jenkins + Docker images.
  # gp3 is the latest-generation SSD type with good baseline performance.
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-jenkins-server"
    Role    = "jenkins"
    Project = var.project_name
  }
}


# =============================================================================
# EC2 Instance #2: Kind Cluster
# =============================================================================
# Purpose:
#   - Runs Docker (kind runs Kubernetes inside Docker containers)
#   - Runs kind (Kubernetes IN Docker — a lightweight local K8s cluster)
#   - Hosts our deployed application accessible on NodePort 30001
#
# After provisioning, Ansible will install Docker + kubectl + kind and
# create a kind cluster with NodePort 30001 mapped to the host.
# =============================================================================
resource "aws_instance" "kind_cluster" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.kind_sg.id]

  # Root EBS volume — 25 GB because kind clusters store container images
  # locally and can eat disk space quickly.
  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-kind-cluster"
    Role    = "kind"
    Project = var.project_name
  }
}


# =============================================================================
# Elastic IP: Jenkins Server
# =============================================================================
# Creates a static public IP address for the Jenkins server.
# "domain = vpc" means this EIP is for use inside a VPC (the modern default).
# =============================================================================
resource "aws_eip" "jenkins_eip" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-jenkins-eip"
    Project = var.project_name
  }
}


# =============================================================================
# Elastic IP: Kind Cluster
# =============================================================================
# Creates a static public IP address for the kind cluster server.
# =============================================================================
resource "aws_eip" "kind_eip" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-kind-eip"
    Project = var.project_name
  }
}


# =============================================================================
# EIP Association: Jenkins Server
# =============================================================================
# This "attaches" the Elastic IP to the Jenkins EC2 instance.
# It's a separate resource because:
#   - You might want to move the EIP to a different instance later
#   - Terraform can recreate the instance without losing the IP
# =============================================================================
resource "aws_eip_association" "jenkins_eip_assoc" {
  instance_id   = aws_instance.jenkins_server.id
  allocation_id = aws_eip.jenkins_eip.id
}


# =============================================================================
# EIP Association: Kind Cluster
# =============================================================================
# Attaches the Elastic IP to the kind cluster EC2 instance.
# =============================================================================
resource "aws_eip_association" "kind_eip_assoc" {
  instance_id   = aws_instance.kind_cluster.id
  allocation_id = aws_eip.kind_eip.id
}
