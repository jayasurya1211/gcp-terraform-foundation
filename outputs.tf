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