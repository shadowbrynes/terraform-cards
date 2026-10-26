# ==========================================
# SNS Topic for Microservice Alerts
# (Matches aws_sns_topic.app_alerts in lambda.tf)
# ==========================================
resource "aws_sns_topic" "app_alerts" {
  name = "cards-service-alerts"
}

# ==========================================
# SNS SMS Subscription (+2348032829243)
# ==========================================
resource "aws_sns_topic_subscription" "sms_alert" {
  topic_arn = aws_sns_topic.app_alerts.arn
  protocol  = "sms"
  endpoint  = "+2348032829243"
}

# ==========================================
# CloudWatch Alarm: High CPU for Auto Scaling Group
# ==========================================
resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "cards-service-asg-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggered when ASG CPU utilization exceeds 80 percent"
  alarm_actions       = [aws_sns_topic.app_alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}
