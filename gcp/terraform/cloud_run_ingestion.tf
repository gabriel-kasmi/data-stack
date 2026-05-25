
resource "google_artifact_registry_repository" "ingestion_repo" {
  repository_id = "ingestion"
  location      = var.region
  format        = "DOCKER"
}

resource "google_service_account" "ingestion" {
  account_id   = "ingestion-job-sa"
  display_name = "ingestion Job Service Account"
}

resource "google_project_iam_member" "ingestion_sa_roles" {
  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter"
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.ingestion.email}"
  role    = each.key
}

resource "google_cloud_run_v2_job" "ingestion" {
  name     = "ingestion-job"
  location = var.region

  template {
    template {
      service_account = google_service_account.ingestion.email
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ingestion_repo.name}/ingestion:latest"
        
        env {
          name = "ingestion_SECRETS"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.ingestion_secrets.secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }
}
