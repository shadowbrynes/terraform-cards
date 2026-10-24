# 1. SNS Topic for Notifications
resource "aws_sns_topic" "app_alerts" {
  name = "springboot-cards-alerts-topic"
}

# 2. SNS Email Subscription
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.app_alerts.arn
  protocol  = "email"
  endpoint  = "naijajournal@gmail.com"
}

# 3. CloudWatch Alarm: High CPU Utilization on Auto Scaling Group (> 75%)
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "springboot-asg-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 75.0
  alarm_description   = "Triggers when Auto Scaling Group CPU utilization exceeds 75% for 4 minutes"
  alarm_actions       = [aws_sns_topic.app_alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

# 4. CloudWatch Alarm: Unhealthy Target Count on ALB Target Group (>= 1)
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts_alarm" {
  alarm_name          = "springboot-alb-unhealthy-hosts-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1.0
  alarm_description   = "Triggers if any target host fails health checks behind the ALB"
  alarm_actions       = [aws_sns_topic.app_alerts.arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }
}
