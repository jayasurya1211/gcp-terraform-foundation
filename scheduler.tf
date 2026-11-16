resource "google_project_service" "scheduler" {
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "scheduler" {
  account_id   = "scheduler-sa"
  display_name = "Cloud Scheduler caller"
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.weather.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_project_iam_member" "scheduler_bq_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_bigquery_dataset_iam_member" "scheduler_bq_editor" {
  dataset_id = module.data_lake.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_storage_bucket_iam_member" "scheduler_raw_reader" {
  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_cloud_scheduler_job" "ingest" {
  name             = "weather-ingest-daily"
  region           = var.region
  schedule         = "0 6 * * *"
  time_zone        = "Asia/Kolkata"
  attempt_deadline = "180s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.weather.name}:run"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [google_project_service.scheduler]
}

resource "google_cloud_scheduler_job" "load_curated" {
  name             = "weather-load-curated-daily"
  region           = var.region
  schedule         = "30 6 * * *"
  time_zone        = "Asia/Kolkata"
  attempt_deadline = "180s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://bigquery.googleapis.com/bigquery/v2/projects/${var.project_id}/jobs"
    headers = {
      "Content-Type" = "application/json"
    }
    body = base64encode(jsonencode({
      configuration = {
        query = {
          query        = file("${path.module}/sql/load_curated.sql")
          useLegacySql = false
        }
      }
      jobReference = {
        projectId = var.project_id
        location  = var.region
      }
    }))

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [google_project_service.scheduler]
}