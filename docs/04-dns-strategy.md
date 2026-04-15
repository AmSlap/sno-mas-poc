# DNS Strategy — SNO FQDN resolution

## Contexte

OpenShift (SNO inclus) exige que les FQDNs suivants résolvent vers l'IP du nœud SNO :

- `api.<cluster_name>.<base_domain>` — endpoint Kubernetes API (port 6443)
- `api-int.<cluster_name>.<base_domain>` — endpoint interne (6443)
- `*.apps.<cluster_name>.<base_domain>` — **wildcard** pour toutes les routes d'applications (console, oauth, user apps)

**Sans DNS correct, `openshift-install` échoue à l'étape bootstrap** (symptôme classique : `Cluster operator authentication has not yet successfully rolled out`).

## Options évaluées

| Option | Pour | Contre |
|---|---|---|
| **IBM Cloud DNS Services** (`ibm_dns_zone` + `ibm_dns_resource_record`) | Cloud-natif, Terraform-friendly, prod-ready | Nécessite un service DNS instancié (non confirmé dans le lab) |
| **`/etc/hosts` sur bastion + SNO** | Zéro dépendance | **Ne supporte pas les wildcards** → il faudrait lister manuellement `console-openshift-console.apps.*`, `oauth-openshift.apps.*`, etc. Fragile dès qu'une Route custom est créée. |
| **dnsmasq sur le bastion** | Supporte wildcards via `address=/.apps.<cluster>.<domain>/<IP>`, simple, isolé à l'environnement lab | Bastion devient un point unique pour la résolution |

## Décision retenue : dnsmasq sur le bastion

Rôle Ansible : `ansible/roles/dns-lab/`
Playbook : `ansible/playbooks/00-bastion-dns.yml` (premier du `site.yml`)

### Fonctionnement

1. Le playbook installe `dnsmasq` sur le bastion.
2. Template `openshift.conf.j2` génère :
   ```
   address=/api.sno.lab.local/<sno_ip>
   address=/api-int.sno.lab.local/<sno_ip>
   address=/.apps.sno.lab.local/<sno_ip>    # wildcard
   server=161.26.0.10
   server=161.26.0.11
   ```
3. Le bastion résout lui-même les FQDNs OCP et forwarde le reste aux résolveurs IBM Cloud privés.
4. Le nœud SNO est configuré (via le rôle `common` au moment de son provisioning) pour utiliser le bastion comme résolveur DNS principal.

### Fallback : /etc/hosts direct

Un output Terraform `etc_hosts_snippet` génère une version statique (non-wildcard) utilisable si dnsmasq n'est pas une option :

```bash
terraform output -raw etc_hosts_snippet | sudo tee -a /etc/hosts
```

Cette approche ne couvre que les FQDNs fixes (console, oauth, downloads). Suffisant pour la démo mais pas pour les déploiements Maximo qui créent des Routes custom.

## Migration vers IBM Cloud DNS Services (Phase 2)

Pour porter sur un vrai client, remplacer la section dnsmasq par :

```hcl
resource "ibm_dns_zone" "cluster" {
  name        = "${var.cluster_name}.${var.cluster_base_domain}"
  instance_id = ibm_resource_instance.dns.guid
  description = "SNO cluster DNS zone"
}

resource "ibm_dns_resource_record" "api" {
  instance_id = ibm_resource_instance.dns.guid
  zone_id     = ibm_dns_zone.cluster.zone_id
  type        = "A"
  name        = "api"
  rdata       = module.sno.private_ip
}
# ... + api-int + wildcard *.apps
```

Non implémenté dans le POC par manque de confirmation sur l'existence d'une instance DNS Services dans le compte cible.
