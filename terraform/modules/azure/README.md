# Azure modules — scaffold

Contract mirror of `modules/ibm/*`. Same variable names → interchangeable at the env level.

## Mapping

| Logical input      | IBM resource                  | Azure equivalent                             |
|--------------------|-------------------------------|----------------------------------------------|
| `cpu`/`memory_gb`  | `profile` (e.g. `bx2-8x32`)   | `vm_size` (e.g. `Standard_D8s_v5`)           |
| `image_ref`        | `ibm_is_image` ID             | `source_image_reference` (publisher/offer/sku/version) |
| `ssh_key_ids`      | `ibm_is_ssh_key` IDs          | `admin_ssh_key.public_key`                   |
| `subnet_id`        | `ibm_is_subnet` ID            | `azurerm_subnet` ID                          |
| `security_group_ids` | `ibm_is_security_group` IDs | `azurerm_network_security_group` ID          |
| `resource_group_id`| Resource group ID             | `azurerm_resource_group.name`                |

## To implement

- `compute/` → `azurerm_linux_virtual_machine` + `azurerm_network_interface`
- `network/` → data sources on `azurerm_virtual_network` / `azurerm_subnet`
- `security/` → `azurerm_network_security_group` + `azurerm_network_security_rule` (per rule)

Not implemented for the 48h POC. The lab env `envs/lab-azure/` would call these with the same variable names as `envs/lab-ibm/`.
