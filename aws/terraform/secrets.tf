
resource "aws_secretsmanager_secret" "dbt_profiles" {
  name                    = "corail-cloud-dbt-profiles"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "dlt_secrets" {
  name                    = "corail-cloud-dlt-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "ingestion_secrets" {
  name                    = "corail-cloud-ingestion-secrets"
  recovery_window_in_days = 0
}
