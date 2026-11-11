resource "google_project_iam_member" "composer_run" {
  count   = var.enable_composer ? 1 : 0
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.composer[0].email}"
}

resource "google_project_iam_member" "composer_bq_jobs" {
  count   = var.enable_composer ? 1 : 0
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.composer[0].email}"
}

resource "google_bigquery_dataset_iam_member" "composer_bq_editor" {
  count      = var.enable_composer ? 1 : 0
  dataset_id = module.data_lake.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.composer[0].email}"
}

resource "google_storage_bucket_iam_member" "composer_raw_reader" {
  count  = var.enable_composer ? 1 : 0
  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.composer[0].email}"
}

resource "google_service_account_iam_member" "composer_acts_as_pipeline" {
  count              = var.enable_composer ? 1 : 0
  service_account_id = google_service_account.pipeline.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.composer[0].email}"
}