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

variable "service_account_email" {
  description = "Service account email allowed to invoke workflow executions"
  type        = string
}

variable "generator_function_url" {
  description = "HTTPS URL of the sample generator function"
  type        = string
}

variable "load_sql" {
  description = "Rendered BigQuery SQL script executed by the workflow"
  type        = string
}

variable "bigquery_location" {
  description = "Location used for BigQuery query jobs"
  type        = string
}