locals {
  # REQUIRED CONFIGURATION
  # TODO: set this to the billing account to associate with the GCP project
  billing_account_id = null
  # TODO: set this based on the outputs from applying the artifacts environment
  docker_repo_id = null

  # OPTIONAL CONFIGURATION
  # Set this if you want your GCP project to be part of an organization
  org_id = null
  # Update these to change the id and name of the GCP project
  project_id   = "template-dev"
  project_name = "infra-new template"
  # Update this to change the region of all gcp resources
  region = "us-central1"
  # Update this to change the zone of all gcp resources
  zone = "us-central1-a"
  # Update this to change the name of the cloud run service
  service_name = "infra-new-template"
}

provider "google" {
  region = local.region
  zone   = local.zone
}

module "environment_gcp_project" {
  source = "../../modules/environment_gcp_project"

  project_id   = local.project_id
  project_name = local.project_name

  org_id             = local.org_id
  billing_account_id = local.billing_account_id
  docker_repo_id     = local.docker_repo_id
}

module "cloud_run_service" {
  source = "../../modules/cloud_run_service"

  project_id = module.environment_gcp_project.project_id
  location   = local.region

  service_name = local.service_name

  database_instance = module.postgres_database.database_instance_connection_name
  database_user     = module.postgres_database.database_user
  database_name     = module.postgres_database.database_name
  secrets = {
    "DATABASE_PASSWORD" : module.postgres_database.database_password_secret_id
  }
  environment = "dev"
}

module "postgres_database" {
  source = "../../modules/cloud_sql_postgres"

  project_id = module.environment_gcp_project.project_id
  # Use a tiny database for dev
  tier = "db-f1-micro"
}
