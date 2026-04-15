variable "name" {
  description = "Security group name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the SG belongs to."
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID."
  type        = string
}

variable "ingress_rules" {
  description = <<-EOT
    List of ingress rules. Each rule:
      - protocol    : "tcp" | "udp" | "icmp" | "all"
      - port_min    : for tcp/udp, start of range. Ignored for icmp/all.
      - port_max    : for tcp/udp, end of range.   Ignored for icmp/all.
      - source_cidr : source CIDR block (e.g. "0.0.0.0/0" or "10.251.128.0/24")
      - description : human-readable purpose (used in tags / comments)
  EOT
  type = list(object({
    protocol    = string
    port_min    = optional(number)
    port_max    = optional(number)
    source_cidr = string
    description = string
  }))

  validation {
    condition     = alltrue([for r in var.ingress_rules : contains(["tcp", "udp", "icmp", "all"], r.protocol)])
    error_message = "protocol must be one of: tcp, udp, icmp, all."
  }
}

variable "tags" {
  type    = list(string)
  default = []
}
