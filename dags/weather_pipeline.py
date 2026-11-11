from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.providers.google.cloud.operators.cloud_run import CloudRunExecuteJobOperator

PROJECT = "de-project-512112"
REGION = "asia-south1"

MERGE_SQL = r"""
MERGE `de-project-512112.de_pipeline_tf.weather_hourly` T
USING (
  SELECT * FROM (
    SELECT
      REGEXP_EXTRACT(_FILE_NAME, r'/([a-z_]+)_\d{8}T') AS city,
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M', t) AS forecast_time,
      hourly.temperature_2m[OFFSET(i)] AS temperature_c,
      latitude,
      longitude,
      _FILE_NAME AS source_file,
      PARSE_TIMESTAMP('%Y%m%dT%H%M%SZ', REGEXP_EXTRACT(_FILE_NAME, r'_(\d{8}T\d{6}Z)\.json')) AS ingest_ts
    FROM `de-project-512112.de_pipeline_tf.raw_weather`,
      UNNEST(hourly.time) AS t WITH OFFSET i
  )
  WHERE TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY city, forecast_time ORDER BY ingest_ts DESC) = 1
) S
ON T.city = S.city AND T.forecast_time = S.forecast_time
WHEN MATCHED AND S.ingest_ts > T.ingest_ts THEN
  UPDATE SET temperature_c = S.temperature_c, source_file = S.source_file, ingest_ts = S.ingest_ts
WHEN NOT MATCHED THEN
  INSERT ROW
"""

DQ_SQL = """
SELECT CASE
  WHEN COUNT(*) = 0 THEN ERROR('dq failed: weather_hourly is empty')
  WHEN COUNTIF(temperature_c IS NULL) > 0 THEN ERROR('dq failed: null temperature_c')
  WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(ingest_ts), HOUR) > 48 THEN ERROR('dq failed: data older than 48h')
  ELSE 'ok'
END AS result
FROM `de-project-512112.de_pipeline_tf.weather_hourly`
"""

with DAG(
    dag_id="weather_pipeline",
    start_date=datetime(2026, 11, 1),
    schedule="@daily",
    catchup=False,
    default_args={"retries": 1, "retry_delay": timedelta(minutes=5)},
    tags=["weather"],
) as dag:
    run_ingest = CloudRunExecuteJobOperator(
        task_id="run_ingest",
        project_id=PROJECT,
        region=REGION,
        job_name="weather-ingest",
    )

    load_curated = BigQueryInsertJobOperator(
        task_id="load_curated",
        location=REGION,
        configuration={"query": {"query": MERGE_SQL, "useLegacySql": False}},
    )

    dq_checks = BigQueryInsertJobOperator(
        task_id="dq_checks",
        location=REGION,
        configuration={"query": {"query": DQ_SQL, "useLegacySql": False}},
    )

    run_ingest >> load_curated >> dq_checks