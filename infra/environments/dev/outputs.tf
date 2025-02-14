
output "project_id" {
  description = "The project ID"
  value       = module.environment_gcp_project.project_id
}

output "service_name" {
  description = "The name of the Cloud Run service"
  value       = module.cloud_run_service.service_name
}

output "service_url" {
  description = "The URL of the Cloud Run service"
  value       = module.cloud_run_service.service_url
}

output "location" {
  description = "The location/region where resources are deployed"
  value       = local.region
}
