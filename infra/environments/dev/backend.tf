# NOTE: we recommend using a remote backend long term
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
