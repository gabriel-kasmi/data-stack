
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.12.0"
    }
  }

  backend "gcs" {
    bucket  = "my-terraform-state-bucket"
    prefix  = "state"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file("${path.module}/../key-tf.json")
}
