data "google_project" "this" {}

resource "google_service_account" "composer" {
  count        = var.enable_composer ? 1 : 0
  account_id   = "composer-worker"
  display_name = "Composer worker"
}

resource "google_project_iam_member" "composer_worker" {
  count   = var.enable_composer ? 1 : 0
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer[0].email}"
}

resource "google_service_account_iam_member" "composer_agent" {
  count              = var.enable_composer ? 1 : 0
  service_account_id = google_service_account.composer[0].name
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:service-${data.google_project.this.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_composer_environment" "main" {
  count  = var.enable_composer ? 1 : 0
  name   = "de-composer-tf"
  region = var.region
  labels = local.labels

  config {
    software_config {
      image_version = "composer-3-airflow-2.10.5"
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = google_service_account.composer[0].email
    }
  }

  depends_on = [
    google_project_iam_member.composer_worker,
    google_service_account_iam_member.composer_agent,
    google_project_service.apis,
  ]
}