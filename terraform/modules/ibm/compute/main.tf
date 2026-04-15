locals {
  # Maps a (cpu, memory) tuple to an IBM VPC instance profile.
  # Extend this map as new sizes are needed — keeping it local to the IBM module
  # isolates provider-specific naming from callers.
  profile_map = {
    "2-8"   = "bx2-2x8"
    "4-16"  = "bx2-4x16"
    "8-32"  = "bx2-8x32"
    "16-64" = "bx2-16x64"
  }
  profile_key = "${var.cpu}-${var.memory_gb}"
  profile     = lookup(local.profile_map, local.profile_key, null)
}

# Fail fast with a clear error if the caller asks for an unmapped size.
resource "null_resource" "profile_check" {
  lifecycle {
    precondition {
      condition     = local.profile != null
      error_message = "No IBM profile mapped for cpu=${var.cpu} memory=${var.memory_gb}. Add it to profile_map."
    }
  }
}

# Optional secondary data volume, created as a standalone resource for clarity
# and attached below. The separate-resource pattern is more robust across IBM
# provider versions than inline volume_prototype and makes it easy to grow the
# volume later without replacing the instance.
resource "ibm_is_volume" "data" {
  count = var.data_volume_gb > 0 ? 1 : 0

  name           = "${var.name}-data"
  profile        = "general-purpose"
  capacity       = var.data_volume_gb
  zone           = var.zone
  resource_group = var.resource_group_id
  tags           = var.tags
}

resource "ibm_is_instance" "this" {
  name           = var.name
  vpc            = data.ibm_is_subnet.this.vpc
  zone           = var.zone
  profile        = local.profile
  image          = var.image_ref
  keys           = var.ssh_key_ids
  resource_group = var.resource_group_id
  tags           = var.tags

  primary_network_interface {
    subnet          = var.subnet_id
    security_groups = var.security_group_ids
  }

  boot_volume {
    name = "${var.name}-boot"
  }

  dynamic "volume_attachments" {
    for_each = ibm_is_volume.data
    content {
      name                             = "${var.name}-data-att"
      volume                           = volume_attachments.value.id
      delete_volume_on_instance_delete = true
    }
  }
}

data "ibm_is_subnet" "this" {
  identifier = var.subnet_id
}
