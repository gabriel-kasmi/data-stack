
resource "aws_iam_role" "dms_vpc_role" {
  name        = "dms-vpc-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "dms.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_vpc_role" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_iam_role" "dms_access_for_endpoint" {
  name        = "dms-access-for-endpoint"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "dms.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_access_for_endpoint" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.dms_access_for_endpoint.name
}

resource "aws_iam_role" "dms_cloudwatch_logs" {
  name        = "dms-cloudwatch-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "dms.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms_cloudwatch_logs.name
}

resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group"
  replication_subnet_group_description = "DMS Subnet Group"
  subnet_ids                           = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_bis.id]
}

resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source-postgres"
  endpoint_type = "source"
  engine_name   = "postgres"
  server_name   = "db.project-id.supabase.co"
  port          = 5432
  username      = var.postgres_username
  password      = var.postgres_password
  database_name = "my_database"
}

resource "aws_dms_endpoint" "target" {
  endpoint_id   = "target-redshift"
  endpoint_type = "target"
  engine_name   = "redshift-serverless"
  server_name   = aws_redshiftserverless_workgroup.default_workgroup.endpoint[0].address
  port          = 5439
  username      = aws_redshiftserverless_namespace.default_namespace.admin_username
  password      = aws_redshiftserverless_namespace.default_namespace.admin_user_password
  database_name = "my_database"
}

resource "aws_dms_replication_config" "default" {
  replication_config_identifier = "dms-serverless"
  resource_identifier           = "dms-serverless"
  replication_type              = "full-load"  # full-load, cdc, full-load-and-cdc
  source_endpoint_arn           = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn           = aws_dms_endpoint.target.endpoint_arn

  compute_config {
    replication_subnet_group_id  = aws_dms_replication_subnet_group.dms_subnet_group.id
    max_capacity_units           = "16"
    min_capacity_units           = "2"
  }

  table_mappings = <<EOF
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "1",
      "rule-action": "include",
      "object-locator": {
        "schema-name": "%",
        "table-name": "%"
      }
    }
  ]
}
EOF
}
