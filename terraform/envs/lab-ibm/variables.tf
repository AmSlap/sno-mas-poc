variable "ibmcloud_api_key" {
  description = "IBM Cloud API key (long-lived). Provide either this OR ibmcloud_iam_token, not both."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ibmcloud_iam_token" {
  description = "IBM Cloud IAM Bearer token (short-lived, ~1h). Typically set via TF_VAR_ibmcloud_iam_token env var and refreshed on expiry."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ibmcloud_account_id" {
  description = "IBM Cloud account ID — used for SSO refresh commands and resource group lookups in multi-account contexts."
  type        = string
  default     = ""
}

variable "region" {
  description = "IBM Cloud region (e.g. eu-de, eu-fr2). Value pending confirmation from Mehdi."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group name. Value pending confirmation from Mehdi."
  type        = string
}

variable "vpc_name" {
  description = "Existing VPC name. Value pending confirmation from Mehdi."
  type        = string
}

variable "subnet_name" {
  description = "Existing subnet name where SNO + NFS VMs attach. Assumed same as bastion subnet pending confirmation."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path on the bastion to the public SSH key used by Ansible to reach SNO/NFS (default: ~/.ssh/id_rsa.pub, pre-staged by Mehdi)."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_key_name" {
  description = "Name to give the SSH key when registered in IBM Cloud."
  type        = string
  default     = "mas-sno-lab-key"
}

variable "rhel_image_name" {
  description = "Stock RHEL image name. Common value: ibm-redhat-9-6-amd64-1 (varies by region, confirm with `ibmcloud is images`)."
  type        = string
  default     = "ibm-redhat-9-6-amd64-1"
}

variable "cluster_base_domain" {
  description = "DNS base domain for the SNO cluster. Used by Ansible to render install-config.yaml and by dnsmasq on the bastion."
  type        = string
  default     = "lab.local"
}

variable "cluster_name" {
  description = "SNO cluster short name. OpenShift URLs become *.apps.<cluster_name>.<cluster_base_domain>."
  type        = string
  default     = "sno"
}

variable "bastion_subnet_cidr" {
  description = "CIDR of the bastion subnet, used to scope SSH and machine-config-server ingress rules."
  type        = string
  default     = "10.251.128.0/24"
}

variable "tags" {
  type    = list(string)
  default = ["project:mas-sno-lab", "managed-by:terraform"]
}
