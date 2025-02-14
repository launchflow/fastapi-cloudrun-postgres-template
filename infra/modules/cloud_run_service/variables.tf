variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "location" {
  type        = string
  description = "The location/region for the Cloud Run service"
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "environment" {
  type        = string
  description = "The environment (dev/prod)"
  default     = null
}

variable "env_vars" {
  type        = map(string)
  description = "Environment variables for the Cloud Run service"
  default     = {}
}

variable "secrets" {
  type        = map(string)
  description = "Secrets for the Cloud Run service"
  default     = {}
}

variable "container_port" {
  type        = number
  description = "The container port for the Cloud Run service"
  default     = 8080
}

variable "database_instance" {
  type        = string
  description = "The name of the Cloud SQL instance"
}

variable "database_user" {
  type        = string
  description = "The username for the Cloud SQL instance"
}

variable "database_name" {
  type        = string
  description = "The name of the Cloud SQL database"
}
