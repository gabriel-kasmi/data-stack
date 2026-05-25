
resource "google_project_service" "default" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudfunctions.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "datastream.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "workflows.googleapis.com",
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_storage_bucket" "data" {
  name     = "data"
  location = var.region
}
