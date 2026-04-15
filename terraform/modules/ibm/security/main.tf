resource "ibm_is_security_group" "this" {
  name           = var.name
  vpc            = var.vpc_id
  resource_group = var.resource_group_id
  tags           = var.tags
}

# Ingress rules — one ibm_is_security_group_rule per entry in var.ingress_rules.
# Protocol-specific nested blocks are emitted via dynamic blocks so the same
# module can create TCP, UDP, ICMP, and "all-protocols" rules.
resource "ibm_is_security_group_rule" "ingress" {
  for_each = { for idx, r in var.ingress_rules : idx => r }

  group     = ibm_is_security_group.this.id
  direction = "inbound"
  remote    = each.value.source_cidr

  dynamic "tcp" {
    for_each = each.value.protocol == "tcp" ? [1] : []
    content {
      port_min = each.value.port_min
      port_max = each.value.port_max
    }
  }

  dynamic "udp" {
    for_each = each.value.protocol == "udp" ? [1] : []
    content {
      port_min = each.value.port_min
      port_max = each.value.port_max
    }
  }

  dynamic "icmp" {
    for_each = each.value.protocol == "icmp" ? [1] : []
    content {
      type = 8  # echo-request
      code = 0
    }
  }

  # protocol == "all" → no nested block, matches everything.
}

# Egress: allow all by default. Tighten later if the security model demands it.
resource "ibm_is_security_group_rule" "egress_all" {
  group     = ibm_is_security_group.this.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}
