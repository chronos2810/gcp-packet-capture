# GCP Packet Capture

<!-- MarkdownTOC autolink=true -->

- [Documentation](#documentation)
- [Preparing GCP Environment](#preparing-gcp-environment)
- [Packet Capture Prerequisites Setup](#packet-capture-prerequisites-setup)

<!-- /MarkdownTOC -->

## Documentation

https://cloud.google.com/vpc/docs/packet-mirroring
https://cloud.google.com/vpc/docs/using-packet-mirroring
https://cloud.google.com/vpc/docs/monitoring-packet-mirroring

https://cloud.google.com/load-balancing/docs/internal

https://registry.terraform.io/modules/terraform-google-modules/vm/google/latest/submodules/instance_template?tab=inputs

## Preparing GCP Environment

We are going to create the following:

- A new GCP Project
- One Compute Engine Virtual Machine Instance for testing
- A firewall rule to allow traffic from our local machine to the VM instance

1. Clone this repo

```bash
git clone https://github.com/cronos2810/gcp-packet-capture.git
```

2. Preparing GCP Environment

```bash
# a) Move to Working dir
cd gcp-packet-capture/project-creation

# b) Create resources
terraform init
terraform validate
terraform plan -var-file 00-terraform.tfvars
terraform apply -var-file 00-terraform.tfvars -auto-approve

# c) Set ENV
export PROJECT_ID=$(terraform output | tail -2 | grep -o gcp-packet-capture-......)
gcloud config set project $PROJECT_ID

# d) Create VM for testing
cd ../compute-engine

# e) Set PROJECT_ID
sed -i "s/PROJECT_ID/$PROJECT_ID/" 00-instance.tf

# f) VM Creation
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# g) Firewall Setup (Local machine to VM)
gcloud compute firewall-rules create local-to-vm \
  --network=default \
  --allow=tcp:22 \
  --description="Allow incoming traffic on TCP port 22" \
  --direction=INGRESS \
  --target-tags=allow-ssh \
  --source-ranges=$(curl api.ipify.org)/32

gcloud compute firewall-rules describe local-to-vm
```

## Packet Capture Prerequisites Setup

```bash

```


