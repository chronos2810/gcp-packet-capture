project_name     = "gcp-packet-capture"
region           = "us-central1"
labels = {
  "environment" = "test"
}
gcp_service_list = [
  "compute.googleapis.com"
]
