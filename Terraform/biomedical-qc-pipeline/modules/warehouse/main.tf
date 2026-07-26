locals {
  load_sql = templatefile("${path.module}/load.sql.tftpl", {
    project_id      = var.project_id
    raw_dataset     = google_bigquery_dataset.raw.dataset_id
    curated_dataset = google_bigquery_dataset.curated.dataset_id
  })
}

resource "google_bigquery_dataset" "raw" {
  dataset_id  = "biomedical_raw"
  description = "Raw dataset for biomedical sample QC pipeline"
  project     = var.project_id
  location    = var.region
}

resource "google_bigquery_dataset_iam_member" "raw_reader" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.service_account_email}"
}

resource "google_bigquery_dataset" "curated" {
  dataset_id  = "biomedical_curated"
  description = "Curated dataset for biomedical sample QC pipeline"
  project     = var.project_id
  location    = var.region
}

resource "google_bigquery_dataset_iam_member" "curated_editor" {
  dataset_id = google_bigquery_dataset.curated.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.service_account_email}"
}

resource "google_bigquery_table" "synthetic_samples_raw" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.raw.dataset_id
  table_id            = "synthetic_samples_raw"
  deletion_protection = false

  external_data_configuration {
    autodetect    = false
    source_format = "NEWLINE_DELIMITED_JSON"
    source_uris = [
      "gs://${var.landing_bucket_name}/${trim(var.object_prefix, "/") != "" ? trim(var.object_prefix, "/") : "samples"}/*.jsonl",
    ]

    schema = file("${path.module}/schemas/synthetic_samples_raw.json")
  }
}

resource "google_bigquery_table" "validated_samples" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.curated.dataset_id
  table_id            = "validated_samples"
  deletion_protection = false

  schema = file("${path.module}/schemas/validated_samples.json")

}

resource "google_bigquery_table" "rejected_samples" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.curated.dataset_id
  table_id            = "rejected_samples"
  deletion_protection = false

  schema = file("${path.module}/schemas/rejected_samples.json")

}

resource "google_bigquery_table" "sample_qc_summary" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.curated.dataset_id
  table_id            = "sample_qc_summary"
  deletion_protection = false

  schema = file("${path.module}/schemas/sample_qc_summary.json")

}

resource "google_bigquery_table" "pipeline_audit" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.curated.dataset_id
  table_id            = "pipeline_audit"
  deletion_protection = false

  schema = file("${path.module}/schemas/pipeline_audit.json")

}