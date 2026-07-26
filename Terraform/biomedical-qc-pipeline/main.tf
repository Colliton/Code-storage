
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  required_apis = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "workflows.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com"
  ])
}

resource "google_project" "pipeline" {
  name            = var.project_id
  project_id      = var.project_id
  billing_account = var.billing_account_id
}

resource "google_project_service" "required_apis" {
  for_each           = local.required_apis
  project            = google_project.pipeline.project_id
  service            = each.value
  disable_on_destroy = false #wyłączyć usługę/API przy niszczeniu projektu?
}

module "iam" {
  source = "./modules/iam"

  project_id = var.project_id
  prefix     = var.prefix

  depends_on = [google_project_service.required_apis]
}

module "generator" {
  source = "./modules/generator"

  project_id            = var.project_id
  region                = var.region
  prefix                = var.prefix
  object_prefix         = var.object_prefix
  service_account_email = module.iam.service_account_email

  depends_on = [google_project_service.required_apis]
}

module "warehouse" {
  source = "./modules/warehouse"

  project_id            = var.project_id
  region                = var.region
  object_prefix         = var.object_prefix
  landing_bucket_name   = module.generator.landing_bucket_name
  service_account_email = module.iam.service_account_email

  depends_on = [google_project_service.required_apis]
}

module "orchestration" {
  source = "./modules/orchestration"

  project_id             = var.project_id
  region                 = var.region
  prefix                 = var.prefix
  service_account_email  = module.iam.service_account_email
  generator_function_url = module.generator.function_url
  load_sql               = module.warehouse.load_sql
  bigquery_location      = var.region

  depends_on = [
    google_project_service.required_apis,
  ]
}

module "scheduler" {
  source = "./modules/scheduler"

  project_id             = var.project_id
  region                 = var.region
  prefix                 = var.prefix
  schedule               = var.schedule
  time_zone              = var.time_zone
  workflow_execution_url = module.orchestration.workflow_execution_url
  service_account_email  = module.iam.service_account_email

  depends_on = [
    google_project_service.required_apis,
  ]
}