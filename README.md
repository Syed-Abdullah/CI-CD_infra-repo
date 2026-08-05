# 🏗️ infra-repo — Infrastructure for CI/CD Demo

> Terraform + Ansible to provision and configure two AWS EC2 instances for a Jenkins CI/CD pipeline deploying to a local Kubernetes (kind) cluster.

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS (us-east-1)                              │
│                                                                     │
│  ┌─────────────────────────┐    ┌─────────────────────────────┐    │
│  │  EC2 #1: Jenkins Server │    │  EC2 #2: Kind Cluster       │    │
│  │  ────────────────────── │    │  ─────────────────────────  │    │
│  │  • Ubuntu 22.04 LTS     │    │  • Ubuntu 22.04 LTS         │    │
│  │  • Jenkins (CI/CD)      │    │  • Docker                   │    │
│  │  • Docker               │    │  • kind (K8s in Docker)     │    │
│  │  • Elastic IP attached  │    │  • kubectl                  │    │
│  │                         │    │  • Elastic IP attached       │    │
│  │  SG: SSH (22)          │    │                              │    │
│  │      Jenkins UI (8080) │    │  SG: SSH (22)               │    │
│  │      All outbound       │    │      NodePort (30001)       │    │
│  └────────────┬────────────┘    │      All outbound            │    │
│               │                 └──────────────┬───────────────┘    │
│               │         SSH + kubectl          │                    │
│               └────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────────────┘
                │                                  │
        http://<EIP>:8080                  http://<EIP>:30001
         (Jenkins UI)                      (Deployed App)
```

### How It Works

1. **Jenkins Server** receives code pushes via GitHub webhooks on port 8080
2. Jenkins builds a Docker image from the app, tags it with the commit SHA
3. Jenkins SSHs into the Kind Cluster server and deploys the image to Kubernetes
4. The app becomes accessible on the Kind server's Elastic IP at port 30001

---

## 📁 Project Structure

```
infra-repo/
├── .gitignore                          # Prevents secrets and state files from being committed
├── README.md                           # This file
│
├── terraform/
│   ├── provider.tf                     # AWS provider config (region, version)
│   ├── backend.tf                      # S3 + DynamoDB remote state backend
│   ├── variables.tf                    # Input variables with defaults
│   ├── example.tfvars                  # Example variable overrides (copy to terraform.tfvars)
│   ├── security_groups.tf              # Firewall rules for both servers
│   ├── ec2.tf                          # EC2 instances + Elastic IPs
│   └── outputs.tf                      # Output values (EIPs, instance IDs)
│
└── ansible/
    ├── ansible.cfg                     # Ansible settings (SSH user, key path, etc.)
    ├── inventory.ini                   # Server list (paste EIPs here after Terraform)
    ├── site.yml                        # Master playbook (runs both roles)
    └── roles/
        ├── jenkins_server/
        │   └── tasks/
        │       └── main.yml            # Docker + Jenkins installation tasks
        └── kind_cluster/
            └── tasks/
                └── main.yml            # Docker + kubectl + kind installation tasks
```

---

## 🚀 Getting Started

### Prerequisites

| Tool      | Version  | Install Guide |
|-----------|----------|---------------|
| Terraform | ≥ 1.5.0  | [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads) |
| Ansible   | ≥ 2.14   | `pip install ansible` |
| AWS CLI   | ≥ 2.x    | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |

You also need:
- An AWS account with programmatic access configured (`aws configure`)
- An existing EC2 key pair (the `.pem` file on your local machine)
- An S3 bucket and DynamoDB table for Terraform remote state (see below)

### Step 0: Create Remote State Resources (One-Time Setup)

Before running Terraform, create the S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket for state storage
aws s3api create-bucket \
  --bucket cicd-demo-terraform-state-bucket \
  --region us-east-1

# Enable versioning on the bucket (safety net for state recovery)
aws s3api put-bucket-versioning \
  --bucket cicd-demo-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name cicd-demo-terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 1: Configure Terraform Variables

```bash
cd terraform/

# Copy the example file and edit with your values
cp example.tfvars terraform.tfvars

# Edit terraform.tfvars — at minimum, change:
#   key_pair_name = "your-actual-keypair-name"
```

### Step 2: Provision Infrastructure with Terraform

```bash
cd terraform/

# Initialize Terraform (downloads provider plugins, configures backend)
terraform init

# Preview what Terraform will create (dry run — no changes made)
terraform plan -var-file="terraform.tfvars"

# Create the infrastructure (type "yes" when prompted)
terraform apply -var-file="terraform.tfvars"
```

After `terraform apply`, you'll see output like:

```
Outputs:

jenkins_eip     = "54.123.45.67"
kind_eip        = "52.98.76.54"
jenkins_instance_id = "i-0abc123def456"
kind_instance_id    = "i-0xyz789ghi012"
```

### Step 3: Update Ansible Inventory

Copy the Elastic IPs from the Terraform output and paste them into `ansible/inventory.ini`:

```ini
[jenkins_server]
54.123.45.67 ansible_host=54.123.45.67

[kind_cluster]
52.98.76.54 ansible_host=52.98.76.54
```

Also update the `ansible_ssh_private_key_file` in `ansible/inventory.ini` and `ansible/ansible.cfg` to point to your `.pem` file.

### Step 4: Configure Servers with Ansible

```bash
cd ansible/

# Test SSH connectivity to all servers
ansible all -m ping

# Run the full playbook (installs everything on both servers)
ansible-playbook site.yml
```

This will:
- **Jenkins Server**: Install Docker + Jenkins, print the initial admin password
- **Kind Cluster**: Install Docker + kubectl + kind, create a K8s cluster with NodePort 30001

### Step 5: Access Your Services

| Service    | URL                           | Notes |
|------------|-------------------------------|-------|
| Jenkins UI | `http://<jenkins_eip>:8080`   | Use the initial admin password from Ansible output |
| Deployed App | `http://<kind_eip>:30001`   | Available after deploying via the CI/CD pipeline |

---

## 🔒 Security Notes

> **⚠️ Demo Disclaimer**: SSH and Jenkins UI are open to `0.0.0.0/0` for demo purposes. In production, these would be restricted to a VPN or bastion host, and Jenkins would sit behind proper authentication — see hardening notes below.

### Hardening Steps Taken

| Measure | Description |
|---------|-------------|
| **Jenkins Authentication** | Jenkins requires authentication on first access (initial admin password). After setup, configure proper user accounts and role-based access control. |
| **No K8s API Exposed** | The Kubernetes API server (port 6443) is NOT exposed publicly. Only NodePort 30001 is open — the minimum needed to access the deployed app. |
| **Secrets Never Committed** | `.gitignore` blocks `.pem` files, `kubeconfig`, `terraform.tfstate`, and `*.tfvars` from being committed. |
| **Minimal Port Exposure** | Only port 30001 is opened — NOT the full NodePort range (30000-32767). |
| **Remote State Encrypted** | Terraform state is encrypted at rest in S3 using SSE. |
| **State Locking** | DynamoDB prevents concurrent state modifications that could corrupt infrastructure. |

### Production Hardening Checklist

If you were to take this to production, here's what you'd add:

- [ ] Restrict SSH access to your IP or a bastion host CIDR
- [ ] Put Jenkins behind an HTTPS load balancer (ALB) with a proper domain and TLS certificate
- [ ] Enable Jenkins CSRF protection and configure RBAC
- [ ] Use AWS Secrets Manager or Parameter Store for sensitive values
- [ ] Enable VPC flow logs for network monitoring
- [ ] Add CloudWatch alarms for instance health
- [ ] Use private subnets + NAT gateway for instances that don't need direct internet access
- [ ] Implement AWS Config rules for compliance monitoring
- [ ] Set up automated backups for Jenkins home directory

---

## 🧹 Teardown

To destroy all infrastructure and stop incurring costs:

```bash
cd terraform/

# Destroy all resources (type "yes" when prompted)
terraform destroy -var-file="terraform.tfvars"
```

> **Note**: This does NOT delete the S3 bucket or DynamoDB table used for state management. Delete those manually if you want to fully clean up.

---

## 📚 Learning Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Getting Started Guide](https://docs.ansible.com/ansible/latest/getting_started/)
- [Jenkins Installation on Linux](https://www.jenkins.io/doc/book/installing/linux/)
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes NodePort Explained](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
