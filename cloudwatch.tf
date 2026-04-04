# ==========================================
# CloudWatch Alarms for Auto Scaling
# ==========================================

# High CPU → Scale Up
resource "aws_cloudwatch_metric_alarm" "clixx_high_cpu_alarm" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Scale up when CPU exceeds 75% for 2 consecutive minutes"
  actions_enabled     = true

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.clixx_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.clixx_scale_up_policy.arn]
}

# Low CPU → Scale Down
resource "aws_cloudwatch_metric_alarm" "clixx_low_cpu_alarm" {
  alarm_name          = "${var.project_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Scale down when CPU drops below 30% for 2 consecutive minutes"
  actions_enabled     = true

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.clixx_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.clixx_scale_down_policy.arn]
}

# ==========================================
# SNS Topic for Alarm Notifications
# ==========================================

resource "aws_sns_topic" "cloudwatch_alarms_topic" {
  name = "${var.project_name}-cloudwatch-alarms"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "alarm_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alarms_topic.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ==========================================
# CloudWatch Dashboard
# ==========================================

resource "aws_cloudwatch_dashboard" "clixx_dashboard" {
  dashboard_name = "${title(var.project_name)}-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          view   = "timeSeries",
          title  = "CPU Utilization (ASG)",
          region = var.aws_region,
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.clixx_asg.name]
          ],
          period = 60,
          stat   = "Average",
          annotations = {
            horizontal = [
              { label = "Scale Up (75%)", value = 75, color = "#ff0000", fill = "above" },
              { label = "Scale Down (30%)", value = 30, color = "#00ff00", fill = "below" }
            ]
          }
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 7,
        width  = 12,
        height = 6,
        properties = {
          view   = "timeSeries",
          title  = "Unhealthy Hosts (ALB)",
          region = var.aws_region,
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", aws_lb.clixx_lb.name, "TargetGroup", aws_lb_target_group.clixx_web_tg.name]
          ],
          period = 60,
          stat   = "Sum"
        }
      },
      {
        type   = "metric",
        x      = 13,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          view   = "timeSeries",
          title  = "Request Count (ALB)",
          region = var.aws_region,
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.clixx_lb.name]
          ],
          period = 60,
          stat   = "Sum"
        }
      },
      {
        type   = "metric",
        x      = 13,
        y      = 7,
        width  = 12,
        height = 6,
        properties = {
          view   = "timeSeries",
          title  = "Healthy Hosts (ALB)",
          region = var.aws_region,
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", aws_lb.clixx_lb.name, "TargetGroup", aws_lb_target_group.clixx_web_tg.name]
          ],
          period = 60,
          stat   = "Average"
        }
      }
    ]
  })
}
