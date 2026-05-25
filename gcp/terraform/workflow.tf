
resource "google_service_account" "workflow" {
  account_id   = "workflow"
  display_name = "workflow"
  create_ignore_already_exists = true
}

resource "google_project_iam_member" "workflow" {
  for_each = toset([
    "roles/cloudfunctions.invoker",
    "roles/run.invoker"
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.workflow.email}"
  role    = each.key
}

resource "google_workflows_workflow" "default" {
  name                = "workflow"
  region              = var.region
  service_account     = google_service_account.workflow.id
  call_log_level      = "LOG_ALL_CALLS"
  deletion_protection = false
  source_contents = <<EOT
  main:
      params: [event]
      steps:
        - launch_ingestion_job:
            call: googleapis.run.v1.namespaces.jobs.run
            args:
              name: "namespaces/" + ${var.project_id} + "/jobs/" + ${google_cloud_run_v2_job.tool.name}
              location: ${var.region}
              body:
                overrides:
                  containerOverrides:
                    env:
                      - name: param
                        value: value

        - launch_dlt:
            call: http.post
            args:
              url: '${google_cloud_run_service.dlt_service.status[0].url}'
              headers:
                Content-Type: "application/json"
              body:
                dlt_params: "test"

        - launch_dbt:
            call: http.post
            args:
              url: '${google_cloud_run_service.dbt_service.status[0].url}'
              headers:
                Content-Type: "application/json"
              body:
                dbt_command: "dbt run"
  EOT
}

resource "google_service_account" "schedule_job" {
  account_id   = "scheduler"
  display_name = "scheduler"
  create_ignore_already_exists = true
}

resource "google_project_iam_member" "schedule_job" {
  for_each = toset([
    "roles/cloudscheduler.admin",
    "roles/workflows.invoker" 
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.schedule_job.email}"
  role    = each.key
}

resource "google_cloud_scheduler_job" "schedule_job" {
  name     = "scheduler-job"
  region   = var.region
  schedule = "0 2 * * *"

  http_target {
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.default.id}}/executions"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.schedule_job.email
    }
  }
}
