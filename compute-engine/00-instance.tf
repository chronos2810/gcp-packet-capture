# https://www.terraform.io/docs/providers/google/r/compute_instance.html
resource "google_compute_instance" "default" {
  name         = "vm-instance"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  project      = "gcp-packet-capture-7z0hbh"

  tags = ["allow-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

 # metadata_startup_script = ""
}
