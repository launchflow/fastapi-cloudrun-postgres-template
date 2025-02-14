
locals {
  docker_project   = regex("projects/(.*?)/", var.docker_repo_id)[0]
  docker_location  = regex("locations/(.*?)/", var.docker_repo_id)[0]
  docker_repo_name = regex("repositories/(.*)", var.docker_repo_id)[0]
}

resource "random_string" "project_suffix" {
  length  = 8
  special = false
  numeric = false
  upper   = false
}

resource "google_project" "gcp_project" {
  name            = var.project_name
  project_id      = "${var.project_id}-${random_string.project_suffix.result}"
  org_id          = var.org_id
  billing_account = var.billing_account_id

  deletion_policy = "DELETE"
}

data "google_compute_network" "default" {
  name    = "default"
  project = google_project.gcp_project.project_id

  depends_on = [google_project_service.compute_api]
}

# Below all GCP APIs that are required for the environment are enabled.
resource "google_project_service" "logging_api" {
  project = google_project.gcp_project.project_id
  service = "logging.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project = google_project.gcp_project.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "secret_manager_api" {
  project = google_project.gcp_project.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloud_run_api" {
  project = google_project.gcp_project.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking_api" {
  project = google_project.gcp_project.project_id
  service = "sqladmin.googleapis.com"

  disable_on_destroy = false
}

data "google_artifact_registry_repository" "docker_repo" {
  project       = local.docker_project
  location      = local.docker_location
  repository_id = local.docker_repo_name
}

# Grant the service account access to read the docker repository
resource "google_artifact_registry_repository_iam_member" "repo_access" {
  project    = data.google_artifact_registry_repository.docker_repo.project
  location   = data.google_artifact_registry_repository.docker_repo.location
  repository = data.google_artifact_registry_repository.docker_repo.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${google_project.gcp_project.number}@serverless-robot-prod.iam.gserviceaccount.com"

  depends_on = [google_project_service.cloud_run_api]
}
