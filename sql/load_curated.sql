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