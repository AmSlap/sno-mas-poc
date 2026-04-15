# Remote state — REQUIRED for "industriel" delivery.
#
# Option 1: IBM Cloud Object Storage (recommended for this lab).
# Option 2: Terraform Cloud (free tier, simpler bootstrap).
#
# For the 48h POC, uncomment Option 2 and create a workspace manually, OR
# wire Option 1 once you have COS credentials from Mehdi.

# --- Option 1: IBM COS (s3-compatible) ---
# terraform {
#   backend "s3" {
#     bucket                      = "mas-sno-tfstate"
#     key                         = "lab-ibm/terraform.tfstate"
#     region                      = "eu-de"
#     endpoint                    = "s3.eu-de.cloud-object-storage.appdomain.cloud"
#     skip_credentials_validation = true
#     skip_region_validation      = true
#     skip_metadata_api_check     = true
#   }
# }

# --- Option 2: Terraform Cloud ---
# terraform {
#   cloud {
#     organization = "your-org"
#     workspaces { name = "mas-sno-lab-ibm" }
#   }
# }
