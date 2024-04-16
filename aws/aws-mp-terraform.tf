provider "aws" {
  region = "eu-central-1"
}

// let generated lambda jar to be replaced each time it changes - based on timestamp
resource "null_resource" "new_jar" {
  triggers = {
    jar_timestamp = timestamp()
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = "mp-lambda"

  filename = "../aws-mp-lambda/target/aws-mp-lambda-1.0-SNAPSHOT.jar"
  handler  = "pl.mg.amp.lambda.LambdaFunctionHandler::handleRequest"
  runtime  = "java21"

  role        = aws_iam_role.lambda_exec.arn
  publish     = true
  timeout     = 60
  memory_size = 512

  source_code_hash = filebase64sha256("../aws-mp-lambda/target/aws-mp-lambda-1.0-SNAPSHOT.jar")

  depends_on = [null_resource.new_jar]
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
    }
  )
}

resource "aws_sqs_queue" "ms_queue" {
  name = "ms-queue"
}

// policies
data "aws_iam_policy_document" "lambda_sqs_policy" {
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ]
    resources = [
      aws_sqs_queue.ms_queue.arn,
    ]
  }
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda_sqs_policy"
  description = "Allows Lambda to send messages to SQS"
  policy      = data.aws_iam_policy_document.lambda_sqs_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

// create ECR repository
resource "aws_ecr_repository" "repository" {
  name = "mg/aws-mp"
  lifecycle {
    ignore_changes = [name]
  }
}

// --- MESSAGE RECEIVER ---

// create ECS cluster
resource "aws_ecs_cluster" "mp-cluster" {
  name = "mp-cluster"
}

// create ECS Fargate task
resource "aws_ecs_task_definition" "mp-task" {
  family                   = "mp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.mp-ecs-execution-role.arn
  task_role_arn            = aws_iam_role.mp-ecs-execution-role.arn


  lifecycle {
    create_before_destroy = true
  }

  container_definitions = jsonencode([
    {
      name              = "mp-container"
      cpu               = 1024
      memory            = 2048
      memoryReservation = 1024
      essential         = true
      image             = "${aws_ecr_repository.repository.repository_url}:latest"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group"  = "true"
          "awslogs-group"         = "/ecs/mp-logs"
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "env.s3_bucket_name",
          value = aws_s3_bucket.s3_bucket.bucket
        }
      ]
    }
  ])
}

// create ECS service
resource "aws_ecs_service" "mp-service" {
  name            = "mp-service"
  cluster         = aws_ecs_cluster.mp-cluster.id
  task_definition = aws_ecs_task_definition.mp-task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = ["sg-04e1a6d5af8c1ba66"]
    subnets          = ["subnet-03a2992334fedce89", "subnet-0e23d59e06f869aa0", "subnet-0d04d84155bcc7721"]
    assign_public_ip = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

// create ECS IAM roles for task execution and service
resource "aws_iam_role" "mp-ecs-execution-role" {
  name = "mp-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_policy_attach" {
  role       = aws_iam_role.mp-ecs-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_full_access_role_policy_attach" {
  role       = aws_iam_role.mp-ecs-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_full_access2_role_policy_attach" {
  role       = aws_iam_role.mp-ecs-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

resource "aws_iam_role_policy_attachment" "sqs_full_access_role_policy_attach" {
  role       = aws_iam_role.mp-ecs-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_readonly_access_role_policy_attach" {
  role       = aws_iam_role.mp-ecs-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess"
}

//-----------  Fargate SQS read policy
data "aws_iam_policy_document" "sqs_policy" {
  statement {
    sid     = "MSFargateSQSAccess"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]
    effect    = "Allow"
    resources = [
      aws_sqs_queue.ms_queue.arn,
    ]
  }
}

resource "aws_iam_policy" "fargate_sqs_policy" {
  name        = "fargate_sqs_policy"
  description = "Allows Lambda to send messages to SQS"
  policy      = data.aws_iam_policy_document.sqs_policy.json
}

// Attach SQS policy to the IAM role that Fargate tasks
resource "aws_iam_role_policy_attachment" "fargate_sqs_access_role_policy_attach" {
  role       = aws_iam_role.mp-ecs-execution-role.name
  policy_arn = aws_iam_policy.fargate_sqs_policy.arn
}

// create S3 bucket for storing received SQS messages
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "aws-ms-bucket"

}
///////////////////// S3 bucket policy
// S3 bucket policy
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid     = "MSFargateS3WriteAccess"
    actions = [
      "s3:PutObject"
    ]
    effect    = "Allow"
    resources = [
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]
  }
}

// S3 IAM policy
resource "aws_iam_policy" "aws_mp_s3_policy" {
  name        = "s3_policy"
  description = "Policy for accessing S3 bucket from Fargate"
  policy      = data.aws_iam_policy_document.s3_policy.json
}

// Fargate task execution role
resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.mp-ecs-execution-role.name
  policy_arn = aws_iam_policy.aws_mp_s3_policy.arn
}

// API Gateway
resource "aws_api_gateway_rest_api" "mp-api-gateway" {
  name        = "mp-api-gateway"
  description = "MP API Gateway for MP lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "root" {
  parent_id   = aws_api_gateway_rest_api.mp-api-gateway.root_resource_id
  path_part   = "mp-lambda"
  rest_api_id = aws_api_gateway_rest_api.mp-api-gateway.id
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.mp-api-gateway.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.mp-api-gateway.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  integration_http_method = "GET"
  type = "AWS"
  uri = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.mp-api-gateway.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.mp-api-gateway.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.mp-api-gateway.id
  stage_name  = "dev"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda_exec.name
}

resource "aws_lambda_permission" "api_gw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.mp-api-gateway.execution_arn}/${aws_api_gateway_deployment.deployment.stage_name}/${aws_api_gateway_method.proxy.http_method}/${aws_api_gateway_resource.root.path_part}"
}



