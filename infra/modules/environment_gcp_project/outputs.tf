output "project_id" {
  value = google_project.gcp_project.project_id
}

output "project_number" {
  value = google_project.gcp_project.number
}

output "default_network" {
  value = data.google_compute_network.default.self_link
}
