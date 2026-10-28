locals {
  apis = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "composer.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
