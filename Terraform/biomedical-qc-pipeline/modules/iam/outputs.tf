output "service_account_email" {
  description = "Service account email for the pipeline runtime"
  value       = google_service_account.pipeline.email
}