locals {
  # REQUIRED CONFIGURATION
  # TODO: set this to the billing account to associate with the GCP project
  billing_account_id = null

  # OPTIONAL CONFIGURATION
  # Set this if you want your GCP project to be part of an organization
  org_id = null
  # Update these to change the id and name of the GCP project
  artifact_repo_project_id   = "artifacts"
  artifact_repo_project_name = "infra-new template artifacts"
  # Update this to change the region of all gcp resources
  region = "us-central1"
  # Update this to change the zone of all gcp resources
  zone = "us-central1-a"
}

provider "google" {
  region = local.region
  zone   = local.zone
}


resource "random_string" "project_suffix" {
  length  = 8
  special = false
  numeric = false
  upper   = false
}

resource "google_project" "gcp_project" {
  name            = local.artifact_repo_project_name
  project_id      = "${local.artifact_repo_project_id}-${random_string.project_suffix.result}"
  org_id          = local.org_id
  billing_account = local.billing_account_id

  deletion_policy = "DELETE"
}

resource "google_project_service" "artifact_registry_api" {
  project = google_project.gcp_project.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = "docker"
  format        = "DOCKER"
  project       = google_project.gcp_project.project_id

  depends_on = [google_project_service.artifact_registry_api]
}

output "project_id" {
  value = google_project.gcp_project.project_id
}

output "docker_repo_id" {
  value = google_artifact_registry_repository.docker_repo.id
}
