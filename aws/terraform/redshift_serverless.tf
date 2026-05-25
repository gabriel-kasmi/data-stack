
resource "aws_iam_role" "redshift" {
  name               = "redshift-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redshift" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonRedshiftQueryEditorV2FullAccess"
  ])
  role       = aws_iam_role.redshift.name
  policy_arn = each.key
}

resource "aws_security_group" "redshift_sg" {
  name   = "redshift-sg"
  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "redshift_outbound_tcp" {
  security_group_id = aws_security_group.redshift_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "redshift_inbound_tcp" {
  security_group_id = aws_security_group.redshift_sg.id
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.default.cidr_block
  from_port         = 5439
  to_port           = 5439
}

# Create a Redshift namespace (like a database instance)
resource "aws_redshiftserverless_namespace" "default_namespace" {
  namespace_name      = "namespace"
  admin_username      = var.redshift_username
  admin_user_password = var.redshift_password
  db_name             = "my_database"
  iam_roles           = [aws_iam_role.redshift.arn]
}

# Create a Redshift workgroup (compute resources)
resource "aws_redshiftserverless_workgroup" "default_workgroup" {
  workgroup_name      = "workgroup"
  namespace_name      = aws_redshiftserverless_namespace.default_namespace.namespace_name
  subnet_ids          = [
    aws_subnet.private_subnet.id, 
    aws_subnet.private_subnet_bis.id, 
    aws_subnet.private_subnet_ter.id
  ]
  security_group_ids  = [aws_security_group.redshift_sg.id]
  publicly_accessible = false
  base_capacity       = 8
  max_capacity        = 8
}
