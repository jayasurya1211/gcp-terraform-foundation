output "bucket_url" {
  value = google_storage_bucket.raw.url
}

output "dataset_id" {
  value = google_bigquery_dataset.analytics.dataset_id
}