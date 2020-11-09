# GCP Packet Capture

<!-- MarkdownTOC autolink=true -->

- [Documentation](#documentation)
- [Preparing GCP Environment](#preparing-gcp-environment)
- [Packet Capture Prerequisites Setup](#packet-capture-prerequisites-setup)
- [Creating the Mirroring Policy](#creating-the-mirroring-policy)
- [Testing](#testing)
    - [TODO](#todo)

<!-- /MarkdownTOC -->

## Documentation

https://cloud.google.com/vpc/docs/packet-mirroring
https://cloud.google.com/vpc/docs/using-packet-mirroring
https://cloud.google.com/vpc/docs/monitoring-packet-mirroring

https://cloud.google.com/load-balancing/docs/internal

https://registry.terraform.io/modules/terraform-google-modules/vm/google/latest/submodules/instance_template?tab=inputs

https://github.com/terraform-google-modules/terraform-google-vm/tree/master/modules/mig

## Preparing GCP Environment

We are going to create the following resources:

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

We are going to create the following resources

- Instance Template
- Managed Instance Group from that template
- TCP Internal Load Balancer

1. Create an Instance Template for the Managed Instance Group

```bash
gcloud beta compute instance-templates create instance-template \
   --machine-type=f1-micro \
   --network=default \
   # --no-address \
   --no-restart-on-failure \
   --maintenance-policy=TERMINATE \
   --tags=allow-ssh \
   --image=debian-9-stretch-v20201014 \
   --image-project=debian-cloud \
   --boot-disk-size=10GB \
   --metadata="startup-script=sudo apt update && sudo apt install apache2 dnsutils tcpdump -y"
```

2. Create and configure the Managed Instance Group

```bash
gcloud compute instance-groups managed create instance-group \
  --base-instance-name=instance-group-vm \
  --template=instance-template \
  --size=1 \
  --zone=us-central1-a

gcloud beta compute instance-groups managed set-autoscaling "instance-group" \
  --zone "us-central1-a" \
  --cool-down-period "60" \
  --max-num-replicas "3" --min-num-replicas "1" \
  --target-cpu-utilization "0.6" \
  --mode "on"
```

3. Internal TCP Load Balancer

```bash
# Create a new regional HTTP health check to test HTTP connectivity to the VMs on 80.
gcloud compute health-checks create http hc-http-80 \
    --region=us-central1 \
    --port=80

# Create a new firewall rule for health checks
gcloud compute firewall-rules create fw-allow-health-checks \
    --network=default \
    --action=ALLOW \
    --direction=INGRESS \
    --source-ranges=35.191.0.0/16,130.211.0.0/22 \
    --target-tags=allow-ssh \
    --rules=tcp

# Create the backend service for HTTP traffic:
gcloud compute backend-services create be-ilb \
    --load-balancing-scheme=internal \
    --protocol=tcp \
    --region=us-central1 \
    --health-checks=hc-http-80 \
    --health-checks-region=us-central1

# Add the instance group to the backend service:
gcloud compute backend-services add-backend be-ilb \
    --region=us-central1 \
    --instance-group=instance-group \
    --instance-group-zone=us-central1-a

# Create a forwarding rule for the backend service.
gcloud compute forwarding-rules create fr-ilb \
    --region=us-central1 \
    --load-balancing-scheme=internal \
    --network=default \
    --subnet=default \
    --ip-protocol=tcp \
    --ports=80 \
    --backend-service=be-ilb \
    --backend-service-region=us-central1 \
    --is-mirroring-collector
```

## Creating the Mirroring Policy

```bash
gcloud compute packet-mirrorings create packet-mirroring-policy-00 \
  --region=us-central1 \
  --network=default \
  --collector-ilb=fr-ilb \
  --mirrored-instances=projects/$PROJECT_ID/zones/us-central1-a/instances/vm-instance
```

## Testing

Generate some traffic on the "vm-instance" and capture it on one of the Instance groups machines with tcpdump 

```bash
tcpdump -i eth0 port not 22
```

### TODO

- Terraform All
