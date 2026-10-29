resource "google_cloud_run_v2_job" "weather" {
  name     = "weather-ingest"
  location = "asia-south1"


  template {
    template {
      service_account = google_service_account.pipeline.email
      max_retries     = 1
      timeout         = "300s"

      containers {
        image = "asia-south1-docker.pkg.dev/de-project-512112/pipeline-images/weather-pipeline:v1"

        env {
          name  = "BUCKET_NAME"
          value = google_storage_bucket.raw.name
        }
        env {
          name  = "CITY"
          value = "hyderabad"
        }
      }
    }
  }

  depends_on = [google_project_service.apis]
}