
resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for ${var.service_name} Cloud Run service"
}


resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.location
  project  = var.project_id

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      # NOTE: this is a placeholder for the image
      # It will be ignored for changes because the release pipeline
      # is done outside of terraform
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        startup_cpu_boost = true
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "INSTANCE_CONNECTION_NAME"
        value = var.database_instance
      }

      env {
        name  = "DATABASE_USER"
        value = var.database_user
      }

      env {
        name  = "DATABASE_NAME"
        value = var.database_name
      }

      volume_mounts {
        mount_path = "/cloudsql"
        name       = "cloudsql"
      }

      ports {
        container_port = var.container_port
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [var.database_instance]
      }
    }

    dynamic "volumes" {
      for_each = var.database_instance != null ? [1] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [var.database_instance]
        }
      }
    }
  }

  # We recommend updating this to true for production
  deletion_protection = false

  depends_on = [google_project_iam_member.secret_accessor]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
