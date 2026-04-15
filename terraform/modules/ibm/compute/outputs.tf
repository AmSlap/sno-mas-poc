output "id" {
  description = "Instance ID."
  value       = ibm_is_instance.this.id
}

output "private_ip" {
  description = "Primary NIC private IPv4."
  value       = ibm_is_instance.this.primary_network_interface[0].primary_ip[0].address
}

output "name" {
  description = "Instance name."
  value       = ibm_is_instance.this.name
}
