resource "aws_iam_role" "lambda_exec_role" {
  name = "springboot-alert-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function_payload.zip"
  source {
    content  = "import json\n\ndef lambda_handler(event, context):\n    print('Received CloudWatch Alarm via SNS:', json.dumps(event))\n    return {'statusCode': 200, 'body': 'Alert processed'}\n"
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "alert_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "springboot-cloudwatch-alert-notifier"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ALERT_EMAIL = "naijajournal@gmail.com"
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.app_alerts.arn
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.app_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alert_function.arn
}
