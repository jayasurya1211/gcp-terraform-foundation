data "google_project" "this" {}

resource "google_service_account" "composer" {
  account_id   = "composer-worker"
  display_name = "Composer worker"
}

resource "google_project_iam_member" "composer_worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_service_account_iam_member" "composer_agent" {
  service_account_id = google_service_account.composer.name
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:service-${data.google_project.this.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_composer_environment" "main" {
  name   = "de-composer-tf"
  region = var.region
  labels = local.labels

  config {
    software_config {
      image_version = "composer-3-airflow-2.10.5"
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = google_service_account.composer.email
    }
  }

  depends_on = [
    google_project_iam_member.composer_worker,
    google_service_account_iam_member.composer_agent,
  ]
}