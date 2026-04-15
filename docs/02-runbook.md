# Runbook

## Pré-requis (une fois)

1. API key IBM Cloud : `ibmcloud iam api-key-create tf-mas-sno --file ~/.ibm-api-key`
2. `export IC_API_KEY=$(jq -r .apikey ~/.ibm-api-key)`
3. COS bucket pour state : `mas-sno-tfstate` (région `eu-de`)
4. Pull-secret Red Hat téléchargé → `~/pull-secret.json`

## Provisioning

```bash
cd terraform/envs/lab-ibm
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars
terraform init
terraform plan -out=plan.out
terraform apply plan.out
terraform output -json > ../../../ansible/terraform-outputs.json
```

## Configuration

```bash
cd ../../../ansible
cp inventory/lab.yml.example inventory/lab.yml
# coller les IPs depuis terraform-outputs.json
scp ~/pull-secret.json sno-node:/root/pull-secret.json
ansible-playbook -i inventory/lab.yml playbooks/site.yml
```

## Validation

```bash
export KUBECONFIG=/root/sno-install/auth/kubeconfig
oc get nodes               # 1 nœud Ready, role master,worker
oc get co                  # tous Available=True
oc get sc                  # nfs-client (default)
oc new-project pvc-test
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: test }
spec:
  accessModes: [ReadWriteOnce]
  resources: { requests: { storage: 1Gi } }
EOF
oc get pvc test            # Bound
```

## Livrables à envoyer à Mehdi

- URL : `oc whoami --show-console`
- Password : `cat /root/sno-install/auth/kubeadmin-password`
- Code : push sur Git + lien

## Teardown

```bash
cd terraform/envs/lab-ibm
terraform destroy
```
