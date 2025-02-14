output "database_user" {
  value = google_sql_user.db_user.name
}

output "database_name" {
  value = google_sql_database.db.name
}

output "database_instance_connection_name" {
  value = google_sql_database_instance.instance.connection_name
}

output "database_password_secret_id" {
  value = google_secret_manager_secret.db_password.secret_id
}
