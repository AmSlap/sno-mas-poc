output "id" {
  description = "Security group ID."
  value       = ibm_is_security_group.this.id
}

output "name" {
  description = "Security group name."
  value       = ibm_is_security_group.this.name
}
