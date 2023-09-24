data "archive_file" "archive" {
  type        = "zip"
  source_file = "greet_lambda.py"
  output_path = "greet_lambda.zip"
}

resource "aws_iam_role" "lambda_iam_role" {
  name = "lambda_iam_role"

  assume_role_policy = <<EOF
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
EOF
}


resource "aws_lambda_function" "lambda_function_test" {
  role             = aws_iam_role.lambda_iam_role.arn
  filename         = "greet_lambda.zip"
  source_code_hash = data.archive_file.archive.output_base64sha256
  function_name    = var.function_name
  handler          = "${var.function_name}.handler"
  runtime          = "python3.9"
  environment {
    variables = {
      greeting = "Lambda function test!"
    }
  }
  depends_on = [aws_iam_role_policy_attachment.iam_policy_attachment]
}


resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 3
}

resource "aws_iam_policy" "lambda_log_policy" {
  name        = "lambda_log_policy"
  path        = "/"
  description = "IAM policy for lambda to log data in cloudwatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_policy_attachment" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}
