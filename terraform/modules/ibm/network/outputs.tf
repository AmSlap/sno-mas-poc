output "vpc_id" {
  value = data.ibm_is_vpc.this.id
}

output "subnet_id" {
  value = data.ibm_is_subnet.this.id
}

output "subnet_cidr" {
  value = data.ibm_is_subnet.this.ipv4_cidr_block
}

output "zone" {
  value = data.ibm_is_subnet.this.zone
}
