resource "google_bigquery_table" "raw_weather" {
  dataset_id          = "de_pipeline_tf"
  table_id            = "raw_weather"
  deletion_protection = false

  external_data_configuration {
    source_format         = "NEWLINE_DELIMITED_JSON"
    source_uris           = ["gs://${google_storage_bucket.raw.name}/raw/weather/*"]
    autodetect            = false
    ignore_unknown_values = true

    schema = jsonencode([
      { name = "latitude", type = "FLOAT" },
      { name = "longitude", type = "FLOAT" },
      { name = "timezone", type = "STRING" },
      {
        name = "hourly", type = "RECORD", fields = [
          { name = "time", type = "STRING", mode = "REPEATED" },
          { name = "temperature_2m", type = "FLOAT", mode = "REPEATED" }
        ]
      }
    ])

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${google_storage_bucket.raw.name}/raw/weather/"
    }
  }

  depends_on = [module.data_lake]
}

resource "google_bigquery_table" "weather_hourly" {
  dataset_id          = "de_pipeline_tf"
  table_id            = "weather_hourly"
  deletion_protection = false
  clustering          = ["city"]

  time_partitioning {
    type  = "DAY"
    field = "forecast_time"
  }

  schema = jsonencode([
    { name = "city", type = "STRING", mode = "REQUIRED" },
    { name = "forecast_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "temperature_c", type = "FLOAT" },
    { name = "latitude", type = "FLOAT" },
    { name = "longitude", type = "FLOAT" },
    { name = "source_file", type = "STRING" },
    { name = "ingest_ts", type = "TIMESTAMP" }
  ])

  depends_on = [module.data_lake]
}