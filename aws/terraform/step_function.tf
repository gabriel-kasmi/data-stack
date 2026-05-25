
resource "aws_iam_role" "step_function" {
  name = "step-function-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "step_function" {
  name   = "step-function-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "ecs:RunTask",
          "iam:PassRole",
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_function" {
  role       = aws_iam_role.step_function.name
  policy_arn = aws_iam_policy.step_function.arn
}

resource "aws_sfn_state_machine" "default" {
  name       = "step-function"
  role_arn   = aws_iam_role.step_function.arn
  definition = jsonencode({
    StartAt = "ingestion_lambda"
    States = {
      "ingestion_lambda" = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.lambda_ingestion.arn
          Payload = {
            "param": "value"
          }
        }
        Next = "dlt_ecs"
      }
      "dlt_ecs" = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.default.arn
          TaskDefinition = aws_ecs_task_definition.dlt_task.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets         = [aws_subnet.private_subnet.id]
              SecurityGroups  = [aws_security_group.ecs_sg.id]
              AssignPublicIp  = "ENABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = jsondecode(aws_ecs_task_definition.dlt_task.container_definitions)[0].name
                Environment = [
                  { Name = "dlt_params", Value = "test" }
                ]
              }
            ]
          }
          EnableExecuteCommand = true
        }
        Next = "dbt_ecs"
      }
      "dbt_ecs" = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.default.arn
          TaskDefinition = aws_ecs_task_definition.dbt_task.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets         = [aws_subnet.private_subnet.id]
              SecurityGroups  = [aws_security_group.ecs_sg.id]
              AssignPublicIp  = "ENABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = jsondecode(aws_ecs_task_definition.dbt_task.container_definitions)[0].name
                Environment = [
                  { Name = "dbt_command", Value = "dbt build" }
                ]
              }
            ]
          }
          EnableExecuteCommand = true
        }
        End = true
      }
    }
  })
}

resource "aws_iam_role" "eventbridge_step_functions" {
  name = "eventbridge-step-functions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "eventbridge_step_functions" {
  name   = "eventbridge-step-functions-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "states:StartExecution"
        Resource = aws_sfn_state_machine.default.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_step_functions" {
  role       = aws_iam_role.eventbridge_step_functions.name
  policy_arn = aws_iam_policy.eventbridge_step_functions.arn
}

resource "aws_cloudwatch_event_rule" "schedule_rule_step_functions" {
  name                = "rule-step-functions"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "step_function_target" {
  rule      = aws_cloudwatch_event_rule.schedule_rule_step_functions.name
  arn       = aws_sfn_state_machine.default.arn
  role_arn  = aws_iam_role.eventbridge_step_functions.arn
}
