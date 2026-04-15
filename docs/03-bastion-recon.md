# Bastion Reconnaissance — 2026-04-15

État des lieux du bastion fourni avec l'environnement lab, avant tout provisioning. Ce document est la source de vérité pour les valeurs à réutiliser dans Terraform et Ansible.

## 1. Accès bastion

| Paramètre | Valeur |
|---|---|
| Host public | `13.122.87.110` |
| Port SSH | `2223` |
| User | `U6ZBWZS` |
| Clé privée (laptop → bastion) | `~/.ssh/lab-bastion.pem` (fichier `.pem` fourni avec l'environnement) |
| Commande SSH | `ssh -i ~/.ssh/lab-bastion.pem -p 2223 U6ZBWZS@13.122.87.110` |

## 2. Système

| Paramètre | Valeur |
|---|---|
| OS | Red Hat Enterprise Linux 9.6 (Plow) |
| Kernel | `5.14.0-570.106.1.el9_6.x86_64` (build Apr 6 2026) |
| Hostname | `itzvsi-afa1a6mj` (préfixe `itzvsi-` = VSI IBM Cloud) |
| Architecture | x86_64 |
| Uptime au moment de la recon | ~16 h (VM provisionnée la veille, 2026-04-14) |
| Utilisateur | `U6ZBWZS` (uid 1001, groupe `wheel`) |
| Sudo | **Passwordless** (`sudo -n true` = 0) |
| SELinux | `unconfined_u:unconfined_r:unconfined_t` (mode permissif pour l'utilisateur) |

### Ressources disque

| Montage | Taille | Utilisé | Libre |
|---|---|---|---|
| `/` | 100 GiB | 3.9 GiB | 96 GiB |
| `/boot` | 495 MiB | 322 MiB | 173 MiB |
| `/efi` | 200 MiB | 7 MiB | 193 MiB |

Aucun volume de données secondaire monté — le bastion tourne sur un disque unique `/dev/vda4`.

## 3. Réseau

| Paramètre | Valeur |
|---|---|
| NIC | `eth0` (alias `ens3`, `enp0s3`) |
| IP privée | `10.251.128.4/24` |
| Gateway | `10.251.128.1` |
| Subnet CIDR | `10.251.128.0/24` |
| DNS primaire | `161.26.0.10` (IBM Cloud private resolver) |
| DNS secondaire | `161.26.0.11` |
| MTU | 1450 (typique VPC IBM Cloud) |

**Implications :**
- L'IP publique `13.122.87.110` est une **Floating IP** mappée en NAT depuis l'extérieur — invisible depuis l'intérieur de la VM.
- Les DNS `161.26.0.x` confirment que le bastion utilise les résolveurs privés IBM Cloud → les endpoints privés IBM (`*.private.cloud.ibm.com`) se résolvent.
- Le subnet `10.251.128.0/24` est probablement le subnet où vivront aussi SNO et NFS (à confirmer via métadonnées ou indication explicite).

## 4. Outils installés

| Outil | Statut | Chemin |
|---|---|---|
| `oc` | ✅ Installé | `/home/U6ZBWZS/.local/bin/oc` |
| `kubectl` | ✅ Installé | `/home/U6ZBWZS/.local/bin/kubectl` |
| `git` | ✅ | `/usr/bin/git` |
| `jq` | ✅ | `/usr/bin/jq` |
| `python3` | ✅ | `/usr/bin/python3` |
| `terraform` | ❌ MISSING | à installer (HashiCorp repo) |
| `ansible` | ❌ MISSING | à installer (EPEL ou pip) |
| `ansible-playbook` | ❌ MISSING | idem |
| `ibmcloud` | ❌ MISSING | à installer (script curl IBM) |
| `helm` | ❌ MISSING | via rôle Ansible `post-install` |
| `openshift-install` | ❌ MISSING | via rôle Ansible `sno-install` |
| `podman` | ❌ MISSING | non nécessaire |
| `docker` | ❌ MISSING | non nécessaire |

**Lecture :** `oc`/`kubectl` sont pré-installés dans `~/.local/bin` du user — signal fort que le bastion est prévu comme **workstation ops**. `terraform`/`ansible`/`openshift-install` sont volontairement absents : à installer proprement et idempotemment via Ansible dans le cadre du livrable.

## 5. Clés SSH — topologie à deux niveaux

**⚠️ Ne pas confondre les deux clés.**

### Clé A : Laptop → Bastion
- **Privée :** sur ton laptop, fichier `.pem` fourni par email
- **Publique :** `~/.ssh/authorized_keys` sur le bastion (725 octets)
- **Usage :** login humain au bastion

### Clé B : Bastion → VMs privées (SNO, NFS)
- **Privée :** `~/.ssh/id_rsa` sur le bastion (3244 octets, RSA-4096, pré-déposée avec l'environnement)
- **Publique :** `~/.ssh/id_rsa.pub` (dérivée avec `ssh-keygen -y -f ~/.ssh/id_rsa`)
- **Usage :** Ansible utilisera cette clé pour se connecter aux VMs créées. Terraform doit enregistrer la partie publique dans IBM Cloud VPC (`ibm_is_ssh_key`).

### Contenu de la clé publique B (à enregistrer dans IBM Cloud)

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCozCtLbE+eegMoIxemZGwduSnrms9IWFgSiY+FJUiDjTyIqT6jD61H3bTQEvcB2VnQSNUTitcaj5OWUpC4hE3fgGtxyUamqemcYT38/46butBW97nJhXKpDsTQ2Aiggn8YJACEfh1utjOSYvNJgvwkrrb3kXTVjWEnXDBZ2T5TCNv5aHpV+VcTLshTA1dd83vj0/qKQm7RwoMRyr1B3kcIU5wcz/hYPCmnQ/x/GoQdvsHMEN3dnQhtkYpD2yntBF2VfNEHhhPiMujp6gxIoAGqCATZoPdqu4jSvRnn09Hg7yQ+pNM8wtjNcfpc5grWtTFfhQUmQboXC6wk0Dinj8CnXuqs2F4ysTMEVTFC/BRLDW91srBoQ8K+BlMAW2kguXpZFve7PHkC+RY+IgKfdtRoNbgWLtd129UeBqhybuUCH37KD8U/RmyhRRr1244EQ0krWEpw2GwDB1LxT+wHM3bRxuAdWkg4KnENGI7GxcoojF5MDsudp3psX1M6aVbjaU9+QtHWgroG1Lds38pJ1Kncukaz8vCWcTRhSGkuHqK/vUqDLAqTvffTTMjr6mUJmZguU7gYEImeeIdEO4zxz0neYgpaz5SVuth2kDQ2VrXECGUE9hqWFCNdmIrU+dOf/W1VY+1A1pKqaAYN1i/ZT7O1vLOTJ1Jp/LLu8X0b2Htwww==
```

**Impact sur le code Terraform :** au lieu de faire un `data "ibm_is_ssh_key"` sur un nom préexistant, on crée la ressource :

```hcl
resource "ibm_is_ssh_key" "lab" {
  name           = "mas-sno-lab-key"
  public_key     = file("~/.ssh/id_rsa.pub")
  resource_group = data.ibm_resource_group.this.id
}
```

## 6. Connectivité sortante

| Cible | Code HTTP | Statut |
|---|---|---|
| `https://cloud.ibm.com` | 302 | ✅ (redirection vers login, normal) |
| `https://mirror.openshift.com` | 302 | ✅ |
| `https://quay.io` | 200 | ✅ |

Internet sortant pleinement fonctionnel — téléchargement de `openshift-install`, `helm`, images de conteneurs, et appels API IBM Cloud sont tous possibles depuis le bastion.

## 7. État IBM Cloud CLI

Non installé sur le bastion → aucune session `ibmcloud` héritée. **Conséquence directe : une API key est obligatoire** pour authentifier Terraform, pas d'option de fallback sur un token CLI en cache.

## 8. Historique utilisateur

Contenu de `~/.bash_history` (pré-recon) :
```
cat ~/.bash_history
cat /etc/redhat-release
lscpu | grep "CPU(s):"
free -h
```

→ Quelques vérifications système basiques ont été faites avant la mise à disposition du bastion. Aucune instruction cachée.

Contenu de `~/.gitconfig` :
```
[http]
    version = HTTP/2
```

→ Pas d'identité git configurée. À faire avant le premier commit :
```bash
git config --global user.name "Ayoub"
git config --global user.email "..."
```

## 9. Ce que l'on sait vs ce qu'il manque

### ✅ Connu

- Accès bastion + sudo
- VPC privé en `10.251.128.0/24`, DNS privés IBM Cloud
- Clé SSH pour les VMs (Clé B) pré-déposée
- `oc`/`kubectl` pré-installés
- Internet sortant OK
- Pas de conflit d'outils (ni terraform ni ansible installés → on démarre propre)

### ❌ À obtenir auprès du propriétaire de l'infrastructure

| Info | Pourquoi |
|---|---|
| **IBM Cloud API key** | Auth du provider Terraform — bloquant |
| **Resource Group** | Tous les resources Terraform en ont besoin |
| **Région / zone** cible | Provider Terraform + sélection AZ |
| **VPC name / ID** | Data source dans module `network` |
| **Subnet name / ID** | Sur lequel attacher SNO + NFS |
| **Pull-secret Red Hat** | Requis par `openshift-install` — ou confirmation qu'on utilise notre propre compte |
| Confirmation que les VMs vont sur le même subnet que le bastion | Influence les règles de security group |

### 🤔 À découvrir tout seul

- Tester le metadata service VPC (`169.254.169.254` ou `api.metadata.cloud.ibm.com`) pour voir si on peut récupérer VPC ID / subnet ID / zone sans intervention externe
- Tester la résolution DNS interne pour vérifier quel FQDN sera nécessaire pour la console OCP

## 10. Prochaines actions

1. **Demander les informations manquantes** (API key / région / VPC / subnet / pull-secret) pour débloquer la partie IBM Cloud
2. **Installer sur le bastion** pendant l'attente :
   - Terraform (repo HashiCorp)
   - Ansible (pip ou dnf)
   - IBM Cloud CLI (script officiel)
3. **Ajuster `terraform/envs/lab-ibm/main.tf`** pour créer `ibm_is_ssh_key` à partir de `~/.ssh/id_rsa.pub` au lieu de référencer une clé existante
4. **Cloner/pousser le repo `mas-sno-lab`** sur le bastion une fois git identité configurée
