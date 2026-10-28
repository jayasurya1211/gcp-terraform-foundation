output "bucket_url" {
  value = module.data_lake.bucket_url
}

output "dataset_id" {
  value = module.data_lake.dataset_id
}

output "airflow_uri" {
  value = google_composer_environment.main.config[0].airflow_uri
}

output "dag_gcs_prefix" {
  value = google_composer_environment.main.config[0].dag_gcs_prefix
}
output "raw_bucket" {
  value = google_storage_bucket.raw.name
}

output "pipeline_sa_email" {
  value = google_service_account.pipeline.email
}

output "artifact_repo" {
  value = "asia-south1-docker.pkg.dev/de-project-512112/${google_artifact_registry_repository.pipeline.repository_id}"
}