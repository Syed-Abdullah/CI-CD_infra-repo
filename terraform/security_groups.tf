# =============================================================================
# SECURITY GROUPS
# =============================================================================
# A Security Group (SG) is a virtual firewall for your EC2 instance.
# It controls what traffic is allowed IN (ingress) and OUT (egress).
#
# Key concepts:
#   - "Ingress" = inbound traffic (someone connecting TO your server)
#   - "Egress"  = outbound traffic (your server connecting OUT to the internet)
#   - "CIDR"    = a way to specify IP ranges (0.0.0.0/0 means "anywhere")
#   - Each rule specifies: protocol, port range, and allowed source/destination
#
# We create TWO separate security groups because the two servers need
# different ports open:
#   Jenkins server → port 8080 (Jenkins web UI and webhook receiver)
#   Kind cluster   → port 30001 (NodePort to reach our deployed app)
# =============================================================================


# =============================================================================
# Security Group: Jenkins Server
# =============================================================================
# This SG allows:
#   INBOUND:
#     - Port 22 (SSH) from anywhere — so we can remotely manage the server
#     - Port 8080 (HTTP) from anywhere — so we can access the Jenkins web UI
#                                         and GitHub can send webhooks
#   OUTBOUND:
#     - All traffic — Jenkins needs to download plugins, pull Docker images,
#                     reach the kind cluster, etc.
#
# ⚠️  SECURITY NOTE: Opening SSH and Jenkins to 0.0.0.0/0 is acceptable for
#     a demo/learning project but NEVER for production. In prod, you would:
#       - Restrict SSH to your IP or a bastion host
#       - Put Jenkins behind a VPN or load balancer with HTTPS
# =============================================================================
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins server - allows SSH and Jenkins UI access"

  # -------------------------
  # INBOUND RULE 1: SSH
  # -------------------------
  # Allows SSH connections from any IP address.
  # Protocol: TCP (SSH always uses TCP)
  # Port: 22 (the standard SSH port)
  ingress {
    description = "Allow SSH from anywhere (demo only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # -------------------------
  # INBOUND RULE 2: Jenkins UI
  # -------------------------
  # Allows HTTP connections to Jenkins on port 8080.
  # Jenkins listens on 8080 by default.
  # GitHub webhooks also hit this port to trigger builds.
  ingress {
    description = "Allow Jenkins UI and webhook access from anywhere (demo only)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # -------------------------
  # OUTBOUND RULE: All traffic
  # -------------------------
  # Allow the server to reach the internet for:
  #   - Downloading Jenkins plugins
  #   - Pulling Docker images from Docker Hub
  #   - Connecting to the kind cluster over SSH
  #   - apt-get updates
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" means ALL protocols (TCP, UDP, ICMP, etc.)
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-jenkins-sg"
    Project = var.project_name
  }
}


# =============================================================================
# Security Group: Kind Cluster
# =============================================================================
# This SG allows:
#   INBOUND:
#     - Port 22 (SSH) from anywhere — so we can manage the server remotely
#     - Port 30001 (NodePort) from anywhere — so we can access our deployed
#       website from a browser. Kubernetes NodePort services expose apps on
#       high ports (30000-32767), and we specifically use 30001.
#   OUTBOUND:
#     - All traffic — the node needs to pull Docker images, etc.
#
# We only open port 30001, NOT the full NodePort range (30000-32767).
# This follows the principle of least privilege: only expose what you need.
# =============================================================================
resource "aws_security_group" "kind_sg" {
  name        = "${var.project_name}-kind-sg"
  description = "Security group for kind cluster - allows SSH and app NodePort access"

  # -------------------------
  # INBOUND RULE 1: SSH
  # -------------------------
  ingress {
    description = "Allow SSH from anywhere (demo only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # -------------------------
  # INBOUND RULE 2: App NodePort
  # -------------------------
  # Only port 30001 — the specific NodePort our Kubernetes service uses.
  # We do NOT open the entire 30000-32767 range.
  ingress {
    description = "Allow app access via NodePort 30001 from anywhere"
    from_port   = 30001
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # -------------------------
  # INBOUND RULE 3: ArgoCD Web UI
  # -------------------------
  # Port 30080 ?" NodePort exposing the ArgoCD web console
  ingress {
    description = "Allow ArgoCD Web UI via NodePort 30080 from anywhere"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # -------------------------
  # OUTBOUND RULE: All traffic
  # -------------------------
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-kind-sg"
    Project = var.project_name
  }
}

