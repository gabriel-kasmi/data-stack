
resource "google_artifact_registry_repository" "dbt_repo" {
  repository_id = "dbt"
  location      = var.region
  format        = "DOCKER"
}

resource "google_service_account" "dbt" {
  account_id   = "dbt-job-sa"
  display_name = "dbt Job Service Account"
}

resource "google_project_iam_member" "dbt_sa_roles" {
  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter"
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.dbt.email}"
  role    = each.key
}

resource "google_cloud_run_v2_job" "dbt" {
  name     = "dbt-job"
  location = var.region

  template {
    template {
      service_account = google_service_account.dbt.email
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.dbt_repo.name}/dbt:latest"
        
        env {
          name = "DBT_PROFILES"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.dbt_profiles.secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }
}
