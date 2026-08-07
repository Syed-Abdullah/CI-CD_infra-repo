# =============================================================================
# OUTPUTS
# =============================================================================
# Outputs are values that Terraform prints to the terminal after `terraform apply`.
# They're useful for:
#   - Seeing important info (like IP addresses) without digging through AWS console
#   - Passing values to other tools (like Ansible's inventory)
#   - Referencing in other Terraform configurations
#
# After running `terraform apply`, you'll see something like:
#
#   jenkins_eip = "54.123.45.67"
#   kind_eip    = "52.98.76.54"
#
# Copy these IPs into your Ansible inventory.ini file.
# You can also retrieve them later with: terraform output
# =============================================================================

output "jenkins_eip" {
  description = "Elastic IP address of the Jenkins server — use this in Ansible inventory and to access Jenkins UI at http://<this-ip>:8080"
  value       = aws_eip.jenkins_eip.public_ip
}

output "kind_eip" {
  description = "Elastic IP address of the kind cluster server — use this in Ansible inventory and to access the deployed app at http://<this-ip>:30001"
  value       = aws_eip.kind_eip.public_ip
}

output "jenkins_instance_id" {
  description = "EC2 Instance ID of the Jenkins server (useful for AWS console troubleshooting)"
  value       = aws_instance.jenkins_server.id
}

output "kind_instance_id" {
  description = "EC2 Instance ID of the kind cluster server"
  value       = aws_instance.kind_cluster.id
}
