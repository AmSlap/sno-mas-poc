# AWS modules — scaffold

Contract mirror of `modules/ibm/*`. Same variable names → interchangeable at the env level.

## Mapping

| Logical input      | IBM resource                  | AWS equivalent                               |
|--------------------|-------------------------------|----------------------------------------------|
| `cpu`/`memory_gb`  | `profile` (e.g. `bx2-8x32`)   | `instance_type` (e.g. `m5.2xlarge`)          |
| `image_ref`        | `ibm_is_image` ID             | `ami` ID                                     |
| `ssh_key_ids`      | `ibm_is_ssh_key` IDs          | `key_name` on `aws_instance`                 |
| `subnet_id`        | `ibm_is_subnet` ID            | `aws_subnet` ID                              |
| `security_group_ids` | `ibm_is_security_group` IDs | `aws_security_group` IDs                     |
| `resource_group_id`| Resource group ID             | N/A — AWS uses tags, not resource groups     |

## To implement

- `compute/` → `aws_instance` + `aws_ebs_volume` + `aws_volume_attachment`
- `network/` → data sources on `aws_vpc` / `aws_subnet`
- `security/` → `aws_security_group` + `aws_security_group_rule`

Not implemented for the 48h POC.
