variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "schedule" {
  description = "Cron schedule for Cloud Scheduler"
  type        = string
}

variable "time_zone" {
  description = "Time zone for Cloud Scheduler"
  type        = string
}

variable "workflow_execution_url" {
  description = "Workflow executions API endpoint URL"
  type        = string
}

variable "service_account_email" {
  description = "Service account used by Cloud Scheduler to invoke the workflow"
  type        = string
}