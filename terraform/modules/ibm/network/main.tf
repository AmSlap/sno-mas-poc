# We consume the existing VPC and subnet rather than creating them —
# the lab VPC is provisioned outside this Terraform stack.

data "ibm_is_vpc" "this" {
  name = var.vpc_name
}

data "ibm_is_subnet" "this" {
  name = var.subnet_name
}
