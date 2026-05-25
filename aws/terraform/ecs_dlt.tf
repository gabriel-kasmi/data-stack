
resource "aws_ecr_repository" "dlt_repo" {
  name         = "dlt"
  force_delete = true
}

resource "aws_cloudwatch_log_group" "ecs_dlt" {
  name = "container-logs-dlt"
  retention_in_days = 7
}

resource "aws_iam_role" "ecs_dlt_exec" {
  name = "ecs-dlt-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_dlt_exec" {
  role       = aws_iam_role.ecs_dlt_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_dlt_task" {
  name = "ecs-dlt-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_dlt_task" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ])
  role       = aws_iam_role.ecs_dlt_task.name
  policy_arn = each.key
}

resource "aws_ecs_task_definition" "dlt_task" {
  family                   = "dlt-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_dlt_exec.arn
  task_role_arn            = aws_iam_role.ecs_dlt_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "dlt-container"
      image     = "${aws_ecr_repository.dlt_repo.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        {
          name = "aws_region"
          value = var.region
        },
      ]
      secrets = [
        {
          name      = "DLT_SECRETS"
          valueFrom = aws_secretsmanager_secret.dlt_secrets.arn
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_dlt.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs-dlt"
        }
      }
    }
  ])
}
