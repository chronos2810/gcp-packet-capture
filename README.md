# GCP Packet Capture

<!-- MarkdownTOC autolink=true -->

- [Documentation](#documentation)
- [Preparing GCP Environment](#preparing-gcp-environment)

<!-- /MarkdownTOC -->

## Documentation

https://cloud.google.com/vpc/docs/packet-mirroring
https://cloud.google.com/vpc/docs/using-packet-mirroring
https://cloud.google.com/vpc/docs/monitoring-packet-mirroring
https://cloud.google.com/load-balancing/docs/internal

## Preparing GCP Environment

1. Clone this repo

```bash
git clone https://github.com/cronos2810/gcp-packet-capture.git
```

2. Preparing GCP Environment

```bash
# Move to Working dir
cd gcp-packet-capture/project-creation

# Create resources
terraform init
terraform validate
terraform plan -var-file 00-terraform.tfvars
terraform apply -var-file 00-terraform.tfvars -auto-approve

# Set ENV
export PROJECT_ID=$(terraform output | tail -2 | grep -o gcp-packet-capture-......)
gcloud config set project $PROJECT_ID

# Create VM for testing
cd ../compute-engine

# Set PROJECT_ID
sed -i "s/PROJECT_ID/$PROJECT_ID/" 00-instance.tf

# VM Creation
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```


