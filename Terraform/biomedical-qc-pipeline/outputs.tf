output "function_url" {
  description = "Cloud Function URL"
  value       = module.generator.function_url
}

output "landing_bucket_name" {
  description = "Landing bucket used by the generator"
  value       = module.generator.landing_bucket_name
}

output "archive_bucket_name" {
  description = "Archive bucket for processed files"
  value       = module.generator.archive_bucket_name
}

output "service_account_email" {
  description = "Service account email used by the pipeline"
  value       = module.iam.service_account_email
}

output "scheduler_job_name" {
  description = "Cloud Scheduler job name"
  value       = module.scheduler.job_name
}

output "workflow_name" {
  description = "Cloud Workflow name"
  value       = module.orchestration.workflow_name
}