
resource "aws_ecr_repository" "lambda_ingestion_repo" {
  name         = "lambda-ingestion"
  force_delete = true
}

resource "aws_iam_role" "lambda_ingestion" {
  name = "lambda-ingestion-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ingestion" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ])
  role       = aws_iam_role.lambda_ingestion.name
  policy_arn = each.key
}

resource "aws_iam_policy" "lambda_ingestion_vpc_access" {
  name        = "lambda-ingestion-vpc-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ingestion_vpc_access" {
  role       = aws_iam_role.lambda_ingestion.name
  policy_arn = aws_iam_policy.lambda_ingestion_vpc_access.arn
}

resource "aws_security_group" "lambda_ingestion" {
  name   = "lambda-ingestion-sg"
  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_ingestion_outbound_tcp" {
  security_group_id = aws_security_group.lambda_ingestion.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lambda_function" "lambda_ingestion" {
  function_name = "lambda-ingestion"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_ingestion_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_ingestion.arn
  timeout       = 900
  memory_size   = 512
  lifecycle {
    replace_triggered_by = [null_resource.lambda_ingestion_image]
  }
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_ingestion.id]
  }
}
