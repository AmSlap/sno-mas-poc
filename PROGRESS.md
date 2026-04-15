# Progress — MAS SNO Lab

État d'avancement du POC 48h.

## Phase 0 — Bastion & reconnaissance ✅

- [x] SSH bastion validé (`U6ZBWZS@13.122.87.110:2223`)
- [x] Reconnaissance système documentée (`docs/03-bastion-recon.md`)
- [x] Clé SSH pré-déposée sur le bastion identifiée (`~/.ssh/id_rsa`)
- [x] Outils installés : Terraform 1.14, Ansible 8.7, IBM Cloud CLI
- [x] Collections Ansible installées : `kubernetes.core`, `ansible.posix`, `community.general`
- [x] Identité git configurée

## Phase 1 — Scaffold Terraform ✅

- [x] Structure Option A : modules par provider (`ibm/`, `azure/`, `aws/`)
- [x] Modules IBM : `compute`, `network`, `security` avec contrat variables cloud-agnostique
- [x] Module `security` : protocoles TCP/UDP/ICMP/all via blocs dynamiques
- [x] Module `compute` : profiles mappés, volumes attachés via resources séparées
- [x] Env `lab-ibm` : SSH key résource, SG rules filled in avec scoping justifié
- [x] Outputs : `console_url`, `etc_hosts_snippet`, `sno_private_ip`, `nfs_private_ip`
- [x] Scaffolds Azure + AWS avec tables de mapping
- [x] `terraform init` OK (provider IBM-Cloud/ibm v1.89)
- [x] `terraform validate` OK, zéro warning
- [x] `terraform fmt -recursive` appliqué

## Phase 2 — Scaffold Ansible ✅

- [x] Playbook `site.yml` orchestrant 5 étapes
- [x] Rôle `dns-lab` : dnsmasq sur bastion pour wildcard `*.apps`
- [x] Rôle `common` : packages, sysctl, swap off, DNS SNO vers bastion
- [x] Rôle `nfs-server` : export configurable, firewalld, sync/no_root_squash
- [x] Rôle `sno-install` : téléchargement des CLIs, render install-config.yaml
- [x] Rôle `post-install` : helm, StorageClass NFS par défaut

## Phase 3 — Credentials reçus ✅

- [x] Auth IBM Cloud : **IAM Bearer token** fourni (session-based, refresh via SSO)
- [x] Account ID : `3021e28c09a04c09ae6b1f843606cfdd`
- [x] Resource group : `Default`
- [x] Région : `eu-gb` (Londres)
- [x] VPC : `itz-vpc-02`
- [x] Subnet : `sn01`
- [ ] Pull-secret Red Hat : à créer via compte développeur gratuit sur developers.redhat.com puis upload sur bastion

## Phase 4 — Exécution (après réception des secrets)

- [ ] Remplir `terraform.tfvars`
- [ ] Configurer remote state (backend IBM COS ou Terraform Cloud)
- [ ] `terraform plan` → itérer jusqu'à propre
- [ ] `terraform apply`
- [ ] `ansible-playbook site.yml`
- [ ] Validation : `oc get nodes`, `oc get co`, test PVC
- [ ] Récupérer URL console + kubeadmin password

## Phase 5 — Connus incomplets (honest flags)

- [ ] **Boot path SNO sur IBM Cloud VPC** : le rôle `sno-install` s'arrête à la génération du install-config. Le passage effectif à un cluster booté (ISO custom via COS ou Assisted Installer) est à finaliser lors de l'exécution, pas avant.
- [ ] **Backend Terraform remote** : commenté dans `backend.tf`, à choisir avant premier `apply`
- [ ] **Modules Azure / AWS** : scaffolds seulement, non implémentés (hors scope 48h)
- [ ] **Migration DNS vers IBM Cloud DNS Services** : `docs/04-dns-strategy.md` décrit le chemin, non codé

## Commits attendus (vérifications de santé)

| Commit | Validation |
|---|---|
| Initial scaffold | `terraform fmt`, structure cohérente |
| DNS strategy + dnsmasq | Playbook lint (`ansible-lint` si installé) |
| Provider fixes | `terraform init` OK |
| Schema compat fixes | `terraform validate` clean, zéro warning |
