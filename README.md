# MAS SNO Lab — Déploiement cloud-agnostique

Infrastructure industrielle pour déployer un cluster **Single Node OpenShift (SNO)** destiné à héberger **IBM Maximo Application Suite (MAS)**, avec stockage persistant NFS dynamique.

Cible actuelle : **IBM Cloud VPC**. Conçu pour porter sur **Azure** et **AWS** via substitution de modules.

## Architecture

```
                    ┌──────────────┐
                    │   Bastion    │  (existant, accès SSH)
                    │ 13.122.87.110│
                    └──────┬───────┘
                           │ SSH privé
              ┌────────────┼────────────┐
              ▼                         ▼
      ┌──────────────┐         ┌──────────────┐
      │  SNO Node    │◄───────►│  NFS Server  │
      │  bx2-8x32    │  NFS    │  bx2-2x8     │
      │  OCP 4.x     │  :2049  │  RHEL 9.6    │
      └──────────────┘         └──────────────┘
```

## Arborescence

```
terraform/
├── modules/
│   ├── ibm/      # implémentation IBM Cloud VPC (complète)
│   ├── azure/    # scaffold — même contrat d'interface
│   └── aws/      # scaffold — même contrat d'interface
└── envs/lab-ibm/ # stack à appliquer

ansible/
├── playbooks/    # orchestration site.yml
└── roles/        # common, nfs-server, sno-install, post-install
```

## Prérequis

- Terraform >= 1.6
- Ansible >= 2.15
- Compte IBM Cloud avec **API key** (Service ID recommandé)
- Pull-secret Red Hat (https://console.redhat.com/openshift/install/pull-secret)
- Clé SSH enregistrée dans IBM Cloud

## Déploiement (séquence)

```bash
# 1. Provisioning infra
cd terraform/envs/lab-ibm
cp terraform.tfvars.example terraform.tfvars  # remplir les valeurs pending Mehdi
terraform init
terraform plan
terraform apply

# 2. Configuration & installation (ordre imposé par site.yml)
cd ../../../ansible
cp inventory/lab.yml.example inventory/lab.yml  # remplir les IPs depuis `terraform output`
ansible-playbook -i inventory/lab.yml playbooks/site.yml
```

Le `site.yml` orchestre dans cet ordre :

| Étape | Playbook | Cible | Rôle |
|---|---|---|---|
| 0 | `00-bastion-dns.yml` | bastion (local) | `dns-lab` — dnsmasq pour résoudre `*.apps.sno.lab.local` |
| 1 | `01-common.yml` | toutes les VMs | `common` — tuning OS, DNS vers bastion pour SNO |
| 2 | `02-nfs-server.yml` | NFS | `nfs-server` — export `/srv/nfs/openshift` |
| 3 | `03-sno-install.yml` | SNO | `sno-install` — `openshift-install`, install-config |
| 4 | `04-post-install.yml` | SNO | `post-install` — helm, StorageClass NFS par défaut |

Voir `docs/04-dns-strategy.md` pour la décision architecturale DNS.

## Livrables

- URL console OpenShift : voir `terraform output console_url`
- Identifiants kubeadmin : voir `terraform output kubeadmin_password` (sensible)
- Code Terraform : `terraform/`
- Playbooks Ansible : `ansible/`

## Portabilité multi-cloud

Pour porter sur Azure/AWS, créer un nouvel env (`envs/lab-azure/`) et appeler `modules/azure/*` avec les mêmes variables d'entrée. Le contrat d'interface (cpu, memory, image_ref, subnet_id, tags) est identique entre les trois modules.
