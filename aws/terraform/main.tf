
resource "aws_s3_bucket" "data" {
  bucket = "data"
}

resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc" }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags   = { Name = "igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  tags   = { Name = "public-route-table" }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone
  tags              = { Name = "public-subnet" }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags          = { Name = "nat-gateway" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id
  tags   = { Name = "private-route-table" }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.default.id
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.zone
  tags              = { Name = "private-subnet" }
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_subnet" "private_subnet_bis" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = var.zone_bis
  tags              = { Name = "private-subnet-bis" }
}

resource "aws_route_table_association" "private_association_bis" {
  subnet_id      = aws_subnet.private_subnet_bis.id
  route_table_id = aws_route_table.private.id
}

resource "aws_subnet" "private_subnet_ter" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = var.zone_ter
  tags              = { Name = "private-subnet-ter" }
}

resource "aws_route_table_association" "private_association_ter" {
  subnet_id      = aws_subnet.private_subnet_ter.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_outbound_tcp" {
  security_group_id = aws_security_group.ecs_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_ecs_cluster" "default" {
  name = "ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  cluster_name       = aws_ecs_cluster.default.name
  capacity_providers = ["FARGATE"]
}
