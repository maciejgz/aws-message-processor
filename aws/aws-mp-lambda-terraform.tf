provider "aws" {
  region = "eu-central-1"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../aws-mp-lambda/target/aws-mp-lambda-1.0-SNAPSHOT.jar"
  output_path = "../aws-mp-lambda/target/aws-mp-lambda-1.0-SNAPSHOT.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "mp-lambda"

  filename         = data.archive_file.lambda_zip.output_path
  handler          = "pl.mg.amp.lambda.LambdaFunctionHandler::handleRequest"
  runtime          = "java21"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
    )
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}