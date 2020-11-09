output "project_id" {
  value = google_project.demo_project.project_id
}

output "project_number" {
  value = google_project.demo_project.number
}

output "gcs_bucket_tfstate" {
  value = google_storage_bucket.tfstate.name
}
