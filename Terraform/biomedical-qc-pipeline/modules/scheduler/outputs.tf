output "job_name" {
  description = "Cloud Scheduler job name"
  value       = google_cloud_scheduler_job.sample_generator.name
}