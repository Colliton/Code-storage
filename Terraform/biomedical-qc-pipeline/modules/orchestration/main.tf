resource "google_workflows_workflow" "pipeline" {
  project         = var.project_id
  region          = var.region
  name            = "${var.prefix}-pipeline-workflow"
  description     = "Workflow scaffold for biomedical pipeline orchestration"
  service_account = var.service_account_email
  deletion_protection = false

  source_contents = <<-EOF
    main:
      params: [args]
      steps:
        - init:
            assign:
              - trigger: $${default(map.get(args, "trigger"), "manual")}

        - invoke_generator:
            try:
              call: http.post
              args:
                url: "${var.generator_function_url}"
                auth:
                  type: OIDC
                headers:
                  Content-Type: application/json
                body:
                  trigger: $${trigger}
              result: generator_response

            retry:
              predicate: $${http.default_retry_predicate}
              max_retries: 3
              backoff:
                initial_delay: 2
                max_delay: 30
                multiplier: 2

        - run_warehouse_sql:
            call: googleapis.bigquery.v2.jobs.insert
            args:
              projectId: "${var.project_id}"
              body:
                configuration:
                  query:
                    query: |
                      ${indent(22, replace(var.load_sql, "\r\n", "\n"))}
                    useLegacySql: false
                jobReference:
                  location: "${var.bigquery_location}"
            result: bigquery_job

        - init_bigquery_polling:
            assign:
              - bigquery_job_id: $${bigquery_job.jobReference.jobId}
              - poll_attempt: 0
              - max_poll_attempts: 120
              - poll_interval_seconds: 2

        - poll_bigquery_job:
            call: googleapis.bigquery.v2.jobs.get
            args:
              projectId: "${var.project_id}"
              jobId: $${bigquery_job_id}
              location: "${var.bigquery_location}"
            result: bigquery_job_status

        - evaluate_poll_result:
            switch:
              - condition: $${bigquery_job_status.status.state == "DONE"}
                next: check_bigquery_job_error
              - condition: $${poll_attempt >= max_poll_attempts}
                next: bigquery_job_timeout
            next: wait_before_next_poll

        - wait_before_next_poll:
            call: sys.sleep
            args:
              seconds: $${poll_interval_seconds}

        - increment_poll_attempt:
            assign:
              - poll_attempt: $${poll_attempt + 1}
            next: poll_bigquery_job

        - bigquery_job_timeout:
            raise:
              code: "BIGQUERY_JOB_TIMEOUT"
              message: "BigQuery job did not reach DONE state within polling limit"
              job_id: $${bigquery_job_id}
              last_state: $${bigquery_job_status.status.state}

        - check_bigquery_job_error:
            switch:
              - condition: $${map.get(bigquery_job_status.status, "errorResult") != null}
                next: bigquery_job_failed
            next: return_result

        - bigquery_job_failed:
            raise:
              code: "BIGQUERY_JOB_FAILED"
              message: "BigQuery job completed with an error"
              job_id: $${bigquery_job_id}
              error_result: $${bigquery_job_status.status.errorResult}

        - return_result:
            return:
              status: "SUCCESS"
              trigger: $${trigger}
              generator_response: $${generator_response.body}
              generator_http_status: $${generator_response.code}
              bigquery_job_id: $${bigquery_job_id}
              bigquery_job_state: $${bigquery_job_status.status.state}
              bigquery_job_complete: $${bigquery_job_status.status.state == "DONE"}
  EOF
}