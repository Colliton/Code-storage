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
  description = "Cron schedule for Cloud Scheduler job"
  type        = string
}

variable "time_zone" {
  description = "Time zone for Cloud Scheduler job"
  type        = string
}

variable "object_prefix" {
  description = "Prefix for generated sample files in the landing bucket"
  type        = string
  default     = "samples"
}

variable "billing_account_id" {
  description = "GCP billing account ID"
  type        = string

}