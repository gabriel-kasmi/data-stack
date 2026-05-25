
resource "google_datastream_connection_profile" "source" {
  connection_profile_id = "postgres-source"
  display_name          = "postgres-source"
  location              = var.region
  postgresql_profile {
    hostname = "db.project-id.supabase.co"
    port     = 5432
    username = var.postgres_username
    password = var.postgres_password
    database = "my_database"
  }
}

resource "google_datastream_connection_profile" "destination" {
  connection_profile_id = "bigquery-destination"
  display_name          = "bigquery-destination"
  location              = var.region
  bigquery_profile {
  }
}

resource "google_datastream_stream" "default" {
  stream_id    = "postgres-to-bigquery"
  display_name = "postgres-to-bigquery"
  location     = var.region
  
  source_config {
    source_connection_profile = google_datastream_connection_profile.source.id
    postgresql_source_config {
      publication      = "publication"
      replication_slot = "replication_slot"
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.destination.id
    bigquery_destination_config {
      single_target_dataset {
        dataset_id = "postgres"
      }
    }
  }

  backfill_all {
  }
}
