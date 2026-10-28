resource "google_storage_bucket" "raw" {
  name                        = "de-project-512112-raw"
  location                    = "asia-south1"
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "pipeline" {
  account_id   = "pipeline-sa"
  display_name = "Weather pipeline job"
}

resource "google_storage_bucket_iam_member" "pipeline_writer" {
  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_artifact_registry_repository" "pipeline" {
  location      = "asia-south1"
  repository_id = "pipeline-images"
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}