output "workflow_name" {
  description = "Cloud Workflow name"
  value       = google_workflows_workflow.pipeline.name
}

output "workflow_execution_url" {
  description = "Workflow executions API endpoint URL"
  value       = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.pipeline.name}/executions"
}