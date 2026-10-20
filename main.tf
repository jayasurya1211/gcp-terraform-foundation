terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "de-project-512112-tfstate"
    prefix = "foundation/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
resource "google_storage_bucket" "raw" {
  name                        = "${var.project_id}-raw-tf"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_bigquery_dataset" "analytics" {
  dataset_id                 = "de_pipeline_tf"
  location                   = var.region
  delete_contents_on_destroy = true
}
locals {
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}