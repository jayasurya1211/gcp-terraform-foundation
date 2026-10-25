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

locals {
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "data_lake" {
  source     = "./modules/data-lake"
  project_id = var.project_id
  region     = var.region
  dataset_id = "de_pipeline_tf"
  labels     = local.labels

  depends_on = [google_project_service.apis]
}
