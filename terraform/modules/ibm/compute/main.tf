locals {
  # Maps a (cpu, memory) tuple to an IBM VPC instance profile.
  profile_map = {
    "2-8"   = "bx2-2x8"
    "4-16"  = "bx2-4x16"
    "8-32"  = "bx2-8x32"
    "16-64" = "bx2-16x64"
  }
  profile_key = "${var.cpu}-${var.memory_gb}"
  profile     = lookup(local.profile_map, local.profile_key, null)
}

resource "null_resource" "profile_check" {
  lifecycle {
    precondition {
      condition     = local.profile != null
      error_message = "No IBM profile mapped for cpu=${var.cpu} memory=${var.memory_gb}. Add it to profile_map."
    }
  }
}

# Optional secondary data volume. Created and attached as separate resources
# (modern IBM provider pattern — the inline volume_attachments block is
# read-only in provider >= 1.60).
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
}

resource "ibm_is_instance_volume_attachment" "data" {
  count = var.data_volume_gb > 0 ? 1 : 0

  instance = ibm_is_instance.this.id
  name     = "${var.name}-data-att"
  volume   = ibm_is_volume.data[0].id

  # Volume is managed by the ibm_is_volume resource above — don't delete it
  # when the attachment is removed; Terraform will handle the volume lifecycle.
  delete_volume_on_attachment_delete = false
  delete_volume_on_instance_delete   = true
}

data "ibm_is_subnet" "this" {
  identifier = var.subnet_id
}
