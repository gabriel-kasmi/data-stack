
resource "google_secret_manager_secret" "dbt_profiles" {
  secret_id = "dbt-profiles"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "dlt_secrets" {
  secret_id = "dlt-secrets"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "ingestion_secrets" {
  secret_id = "ingestion-secrets"
  replication {
    auto {}
  }
}
