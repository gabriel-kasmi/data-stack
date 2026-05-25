
resource "google_bigquery_dataset" "default" {
  dataset_id                  = "my_database"
  friendly_name               = "my_database"
  description                 = "Main dataset for the datastack"
  location                    = var.region
  delete_contents_on_destroy = true
}
