variable "vpc_name" {
  description = "Existing VPC name to look up (data source — we do not create the VPC)."
  type        = string
}

variable "subnet_name" {
  description = "Existing subnet name to look up."
  type        = string
}

variable "resource_group_id" {
  type = string
}
