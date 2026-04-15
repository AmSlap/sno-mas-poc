# Cloud-neutral inputs — same contract as modules/azure/compute and modules/aws/compute.
# Swapping providers means re-implementing this module's main.tf, NOT changing its caller.

variable "name" {
  description = "Logical instance name (used for tags and hostname)."
  type        = string
}

variable "cpu" {
  description = "vCPU count. Mapped to a provider-specific profile inside main.tf."
  type        = number
}

variable "memory_gb" {
  description = "RAM in GiB. Mapped to a provider-specific profile inside main.tf."
  type        = number
}

variable "image_ref" {
  description = "Provider-specific image identifier (IBM image ID, Azure URN, AWS AMI)."
  type        = string
}

variable "ssh_key_ids" {
  description = "List of SSH key identifiers pre-registered with the provider."
  type        = list(string)
}

variable "subnet_id" {
  description = "Subnet identifier where the primary NIC attaches."
  type        = string
}

variable "security_group_ids" {
  description = "Security group identifiers to attach to the primary NIC."
  type        = list(string)
}

variable "resource_group_id" {
  description = "IBM Cloud resource group ID. (Ignored on other providers — kept for symmetry.)"
  type        = string
}

variable "zone" {
  description = "Availability zone (e.g. eu-de-1)."
  type        = string
}

variable "tags" {
  description = "Tags applied to the instance."
  type        = list(string)
  default     = []
}

variable "data_volume_gb" {
  description = "Optional secondary data volume size in GiB. 0 = no extra volume."
  type        = number
  default     = 0
}
