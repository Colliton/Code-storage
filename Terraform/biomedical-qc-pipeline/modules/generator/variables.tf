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
  description = "Service account email for the Cloud Function"
  type        = string
}

variable "object_prefix" {
  description = "Prefix for the generated sample files in the landing bucket"
  type        = string
  default     = "samples"
}