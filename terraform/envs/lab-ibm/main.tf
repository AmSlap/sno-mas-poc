provider "ibm" {
  # Accept either a long-lived API key OR a short-lived IAM Bearer token.
  # Set one of them via TF_VAR_ibmcloud_api_key / TF_VAR_ibmcloud_iam_token
  # (env vars keep the credential out of tfvars and git).
  ibmcloud_api_key = var.ibmcloud_api_key != "" ? var.ibmcloud_api_key : null
  iam_token        = var.ibmcloud_iam_token != "" ? var.ibmcloud_iam_token : null
  region           = var.region
}

# -----------------------------------------------------------------------------
# Data sources — existing IBM Cloud context
# -----------------------------------------------------------------------------
data "ibm_resource_group" "this" {
  name = var.resource_group_name
}

data "ibm_is_image" "rhel" {
  name = var.rhel_image_name
}

# -----------------------------------------------------------------------------
# SSH key — upload the public half of the keypair Mehdi pre-staged at
# ~/.ssh/id_rsa on the bastion. Ansible will use the private half to reach the
# created VMs.
# -----------------------------------------------------------------------------
resource "ibm_is_ssh_key" "lab" {
  name           = var.ssh_key_name
  public_key     = trimspace(file(pathexpand(var.ssh_public_key_path)))
  resource_group = data.ibm_resource_group.this.id
  tags           = var.tags
}

# -----------------------------------------------------------------------------
# Network — consume the existing VPC + subnet (lab VPC is pre-provisioned)
# -----------------------------------------------------------------------------
module "network" {
  source = "../../modules/ibm/network"

  vpc_name          = var.vpc_name
  subnet_name       = var.subnet_name
  resource_group_id = data.ibm_resource_group.this.id
}

# -----------------------------------------------------------------------------
# Security groups
# -----------------------------------------------------------------------------
# Rules reflect the email requirements (6443, 443, 80 for SNO; 2049 for NFS)
# plus what SNO actually needs to install/run (SSH, 22623 machine-config).
#
# Scoping choices:
#   - 6443/443/80 → 0.0.0.0/0 : lab accepts public exposure (email said to open them)
#   - 22          → bastion subnet only : SSH is not a public-internet service
#   - 22623       → bastion + SNO subnet : internal OCP mechanism, must never be public
#   - 2049 (NFS)  → SNO subnet only : prevents cross-tenant / internet mounts
locals {
  sno_ingress = [
    { protocol = "tcp", port_min = 22, port_max = 22, source_cidr = var.bastion_subnet_cidr,
    description = "SSH from bastion subnet" },
    { protocol = "tcp", port_min = 6443, port_max = 6443, source_cidr = "0.0.0.0/0",
    description = "Kubernetes API" },
    { protocol = "tcp", port_min = 443, port_max = 443, source_cidr = "0.0.0.0/0",
    description = "OpenShift console + *.apps HTTPS" },
    { protocol = "tcp", port_min = 80, port_max = 80, source_cidr = "0.0.0.0/0",
    description = "*.apps HTTP" },
    { protocol = "tcp", port_min = 22623, port_max = 22623, source_cidr = var.bastion_subnet_cidr,
    description = "OCP machine-config server — never expose publicly" },
  ]

  nfs_ingress = [
    { protocol = "tcp", port_min = 22, port_max = 22, source_cidr = var.bastion_subnet_cidr,
    description = "SSH from bastion subnet" },
    { protocol = "tcp", port_min = 2049, port_max = 2049, source_cidr = module.network.subnet_cidr,
    description = "NFSv4 from SNO subnet only" },
    { protocol = "udp", port_min = 2049, port_max = 2049, source_cidr = module.network.subnet_cidr,
    description = "NFSv3 UDP from SNO subnet only" },
  ]
}

module "sno_sg" {
  source            = "../../modules/ibm/security"
  name              = "${var.cluster_name}-sno-sg"
  vpc_id            = module.network.vpc_id
  resource_group_id = data.ibm_resource_group.this.id
  ingress_rules     = local.sno_ingress
  tags              = concat(var.tags, ["role:sno"])
}

module "nfs_sg" {
  source            = "../../modules/ibm/security"
  name              = "${var.cluster_name}-nfs-sg"
  vpc_id            = module.network.vpc_id
  resource_group_id = data.ibm_resource_group.this.id
  ingress_rules     = local.nfs_ingress
  tags              = concat(var.tags, ["role:nfs"])
}

# -----------------------------------------------------------------------------
# Compute — SNO node + NFS server
# -----------------------------------------------------------------------------
module "sno" {
  source             = "../../modules/ibm/compute"
  name               = "${var.cluster_name}-node"
  cpu                = 8
  memory_gb          = 32
  image_ref          = data.ibm_is_image.rhel.id
  ssh_key_ids        = [ibm_is_ssh_key.lab.id]
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.sno_sg.id]
  resource_group_id  = data.ibm_resource_group.this.id
  zone               = module.network.zone
  tags               = concat(var.tags, ["role:sno"])
  data_volume_gb     = 200
}

module "nfs" {
  source             = "../../modules/ibm/compute"
  name               = "${var.cluster_name}-nfs"
  cpu                = 2
  memory_gb          = 8
  image_ref          = data.ibm_is_image.rhel.id
  ssh_key_ids        = [ibm_is_ssh_key.lab.id]
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.nfs_sg.id]
  resource_group_id  = data.ibm_resource_group.this.id
  zone               = module.network.zone
  tags               = concat(var.tags, ["role:nfs"])
  data_volume_gb     = 500
}
