variable "project_name" {
  type        = string
  description = "The name of the GCP project"
}

variable "project_id" {
  type        = string
  description = "The ID of the GCP project"
}

variable "org_id" {
  type        = string
  nullable    = true
  description = "The ID of the GCP organization. If not set the GCP project will not be created in an organization"
}

variable "billing_account_id" {
  type        = string
  nullable    = false
  description = "The ID of the GCP billing account. This is required because we will be using GCP apis that require billing."
}

variable "docker_repo_id" {
  type        = string
  nullable    = false
  description = "The ID of the Docker repository"
}
