output "sno_private_ip" {
  description = "Private IPv4 of the SNO node. Used by Ansible inventory and dnsmasq config."
  value       = module.sno.private_ip
}

output "nfs_private_ip" {
  description = "Private IPv4 of the NFS server."
  value       = module.nfs.private_ip
}

output "subnet_cidr" {
  description = "CIDR of the subnet hosting SNO + NFS."
  value       = module.network.subnet_cidr
}

output "ssh_key_id" {
  description = "IBM Cloud ID of the registered SSH key."
  value       = ibm_is_ssh_key.lab.id
}

output "console_url" {
  description = "Predicted OpenShift console URL (DNS must be resolvable, see docs/04-dns-strategy.md)."
  value       = "https://console-openshift-console.apps.${var.cluster_name}.${var.cluster_base_domain}"
}

# Pre-rendered /etc/hosts block for the bastion, in case dnsmasq is not used.
# Append the content of this output to /etc/hosts on the bastion after apply:
#   terraform output -raw etc_hosts_snippet | sudo tee -a /etc/hosts
output "etc_hosts_snippet" {
  description = "/etc/hosts entries mapping OCP FQDNs to the SNO private IP (fallback if dnsmasq isn't used)."
  value       = <<-EOT
    ${module.sno.private_ip} api.${var.cluster_name}.${var.cluster_base_domain}
    ${module.sno.private_ip} api-int.${var.cluster_name}.${var.cluster_base_domain}
    ${module.sno.private_ip} console-openshift-console.apps.${var.cluster_name}.${var.cluster_base_domain}
    ${module.sno.private_ip} oauth-openshift.apps.${var.cluster_name}.${var.cluster_base_domain}
    ${module.sno.private_ip} downloads-openshift-console.apps.${var.cluster_name}.${var.cluster_base_domain}
  EOT
}
