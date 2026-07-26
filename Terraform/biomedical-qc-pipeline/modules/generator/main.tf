resource "google_storage_bucket" "landing" {
  name                        = "${var.project_id}-${var.prefix}-sample-landing"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket" "archive" {
  name                        = "${var.project_id}-${var.prefix}-sample-archive"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }
}

resource "google_storage_bucket_iam_member" "function_landing_storage_access" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_storage_bucket_iam_member" "function_archive_storage_access" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

data "archive_file" "function" {
  type        = "zip"
  output_path = "${path.module}/generator.zip"
  source_dir  = "${path.module}/function"
}

resource "google_storage_bucket_object" "source" {
  name   = "function-source-${data.archive_file.function.output_md5}.zip"
  bucket = google_storage_bucket.landing.name
  source = data.archive_file.function.output_path
}

resource "google_cloudfunctions2_function" "sample_generator" {
  name        = "${var.prefix}-sample-generator"
  location    = var.region
  description = "Sample generator function"
  build_config {
    runtime     = "python312"
    entry_point = "generate"
    source {
      storage_source {
        bucket = google_storage_bucket.landing.name
        object = google_storage_bucket_object.source.name
      }
    }
  }
  service_config {
    service_account_email = var.service_account_email
    available_memory      = "256M"
    timeout_seconds       = 60
    max_instance_count    = 1
    environment_variables = {
      BUCKET_NAME         = google_storage_bucket.landing.name
      OBJECT_PATH         = var.object_prefix
      ARCHIVE_BUCKET_NAME = google_storage_bucket.archive.name
    }
  }

  depends_on = [
    google_storage_bucket_iam_member.function_landing_storage_access,
    google_storage_bucket_iam_member.function_archive_storage_access,
  ]

}

resource "google_cloud_run_v2_service_iam_member" "sample_generator_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloudfunctions2_function.sample_generator.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account_email}"
}