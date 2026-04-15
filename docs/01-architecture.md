# Architecture

## Decision: modules per provider (Option A)

Chaque provider cloud a son propre sous-dossier dans `terraform/modules/` (`ibm/`, `azure/`, `aws/`). Les trois exposent le **même contrat de variables** (`cpu`, `memory_gb`, `image_ref`, `subnet_id`, `security_group_ids`, `resource_group_id`, `zone`, `tags`).

Conséquence : pour porter le lab sur Azure, on crée `envs/lab-azure/` avec un `main.tf` identique à `envs/lab-ibm/main.tf`, en remplaçant `source = "../../modules/ibm/compute"` par `source = "../../modules/azure/compute"`. **Les valeurs des variables changent (ex: `image_ref`), pas leur forme.**

Pourquoi pas option B (un seul module avec provider-alias) : HashiCorp déconseille les `count = var.cloud == "ibm" ? 1 : 0` dans un même module — ça casse à la première différence structurelle entre providers.

Pourquoi pas option C (un env par cloud sans modules partagés) : duplication garantie, impossible de garantir la symétrie du contrat.

## Décomposition en 3 couches

| Couche       | Outil      | Responsabilité                                                                 |
|--------------|------------|--------------------------------------------------------------------------------|
| Infrastructure | Terraform | VMs, subnets référencés, security groups, clés SSH                             |
| OS / Middleware| Ansible   | tuning sysctl, installation NFS, pré-requis OCP, outils CLI (oc, helm)         |
| OpenShift    | Ansible (openshift-install) | cluster SNO, StorageClass dynamique, validation                  |

Séparation Terraform/Ansible : Terraform ne fait aucune config post-boot (pas de `user_data` scripts d'install, pas de `provisioner "remote-exec"`). Tout ce qui vit dans le système d'exploitation est piloté par Ansible.

## Flux de données

```
terraform apply
  ├─► IBM VPC: 2 VMs + SGs
  └─► outputs: sno_private_ip, nfs_private_ip

ansible-playbook site.yml
  ├─► 01-common     (toutes VMs : packages, sysctl, swap off)
  ├─► 02-nfs-server (NFS VM   : export /srv/nfs/openshift)
  ├─► 03-sno-install (SNO VM  : openshift-install → cluster up)
  └─► 04-post-install (SNO VM : helm, nfs-provisioner, StorageClass default)
```

## Points critiques

- **DNS** : OCP exige `api.<cluster>.<base_domain>` et `*.apps.<cluster>.<base_domain>`. Dans un lab sans DNS externe, on utilise `/etc/hosts` sur le bastion ou un dnsmasq local. À confirmer selon ce qui tourne déjà dans le VPC.
- **Pull-secret Red Hat** : uploadé manuellement sur le nœud SNO avant `03-sno-install`. Non commité.
- **State Terraform** : à héberger sur IBM COS (backend `s3`) avant toute application — voir `backend.tf`.
