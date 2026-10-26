variable "telegram_bot_token" {
  type        = string
  description = "Telegram Bot Token for alert notifications"
  sensitive   = true
}

variable "telegram_chat_id" {
  type        = string
  description = "Telegram Chat ID for receiving alert notifications"
}

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
    content  = <<PYTHON
import json
import os
import urllib.request

def lambda_handler(event, context):
    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")

    for record in event.get("Records", []):
        sns_msg = record.get("Sns", {}).get("Message", "")
        subject = record.get("Sns", {}).get("Subject", "AWS Cards Service Alert")

        text = f"🚨 *{subject}*\n\n{sns_msg}"

        if bot_token and chat_id:
            url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            payload = json.dumps({
                "chat_id": chat_id,
                "text": text
            }).encode("utf-8")
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(req) as resp:
                    print("Dispatched to Telegram successfully:", resp.read().decode())
            except Exception as e:
                print("Failed to dispatch to Telegram:", e)

    return {"statusCode": 200, "body": "Alert processed"}
PYTHON
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
      TELEGRAM_BOT_TOKEN = var.telegram_bot_token
      TELEGRAM_CHAT_ID   = var.telegram_chat_id
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
