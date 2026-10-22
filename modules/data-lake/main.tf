resource "google_storage_bucket" "raw" {
  name                        = "${var.project_id}-${var.bucket_suffix}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  labels                      = var.labels
}

resource "google_bigquery_dataset" "analytics" {
  dataset_id                 = var.dataset_id
  location                   = var.region
  delete_contents_on_destroy = true
  labels                     = var.labels
}