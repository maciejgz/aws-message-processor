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

  role    = aws_iam_role.lambda_exec.arn
  publish = true
  timeout = 60
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
resource "aws_ecs_cluster" "cluster" {
  name = "mp-fargate-cluster"
}

// create ECS Fargate task - TODO

// create ECS service - TODO

// create ECS IAM roles for task execution and service - TODO

//-----------  Fargate SQS read policy
data "aws_iam_policy_document" "sqs_policy" {
  statement {
    sid = "MSFargateSQSAccess"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]
    effect = "Allow"
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

// TODO: Attach SQS policy to the IAM role that Fargate tasks


// create S3 bucket for storing received SQS messages
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "aws-ms-bucket"

}
///////////////////// S3 bucket policy
// S3 bucket policy
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "MSFargateS3WriteAccess"
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.s3_bucket.arn,
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

// TODO: Attach S3 policy to the IAM role that Fargate tasks will assume
// This is a placeholder and should be replaced with your actual Fargate task execution role
/*resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = "replace_with_your_fargate_task_execution_role"
  policy_arn = aws_iam_policy.aws_mp_s3_policy.arn
}*/







