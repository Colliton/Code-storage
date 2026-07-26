resource "google_cloud_scheduler_job" "sample_generator" {
  name        = "${var.prefix}-workflow-schedule"
  description = "Triggers orchestration workflow"
  schedule    = var.schedule
  time_zone   = var.time_zone
  region      = var.region

  http_target {
    uri         = var.workflow_execution_url
    http_method = "POST"

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      argument = jsonencode({
        trigger = "cloud-scheduler"
      })
    }))

    oauth_token {
      service_account_email = var.service_account_email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}