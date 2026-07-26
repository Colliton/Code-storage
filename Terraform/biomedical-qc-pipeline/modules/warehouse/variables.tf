variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "landing_bucket_name" {
  description = "Name of the landing storage bucket"
  type        = string
}

variable "service_account_email" {
  description = "Service account email granted access to BigQuery datasets"
  type        = string
}

variable "object_prefix" {
  description = "Prefix for the generated sample files in the landing bucket"
  type        = string
  default     = "samples"
}