
resource "google_sql_database_instance" "instance" {
  # TODO: change this to postgres-instance
  name             = "infra-new-instance"
  database_version = "POSTGRES_15"
  project          = var.project_id

  settings {
    tier = var.tier
    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "ENCRYPTED_ONLY"
    }
  }

  // We recommend updating this to true for production
  deletion_protection = false
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "database-password"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.password.result

  # NOTE: this depends on just helps insure the project is set up before the secret is created
  depends_on = [google_sql_database_instance.instance]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.password.result
}

resource "google_sql_user" "db_user" {
  name     = "postgres-user"
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
  project  = var.project_id
}

resource "google_sql_database" "db" {
  name     = "postgres-db"
  instance = google_sql_database_instance.instance.name
  project  = var.project_id

  # This is here just to make clean up from `terraform destroy` simpler
  deletion_policy = "ABANDON"
}
