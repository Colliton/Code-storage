output "landing_bucket_name" {
  description = "The name of the landing bucket created by the generator module"
  value       = google_storage_bucket.landing.name
}

output "archive_bucket_name" {
  description = "The name of the archive bucket created by the generator module"
  value       = google_storage_bucket.archive.name
}

output "function_url" {
  description = "The URL of the Cloud Function created by the generator module"
  value       = google_cloudfunctions2_function.sample_generator.service_config[0].uri
}

output "function_name" {
  description = "The name of the Cloud Function"
  value       = google_cloudfunctions2_function.sample_generator.name
}