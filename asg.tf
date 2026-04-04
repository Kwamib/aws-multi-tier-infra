# ==========================================
# Auto Scaling Group
# ==========================================

resource "aws_autoscaling_group" "clixx_asg" {
  launch_template {
    id      = aws_launch_template.clixx_web_app.id
    version = "$Latest"
  }

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  vpc_zone_identifier       = [for subnet in aws_subnet.private_subnets : subnet.id]
  health_check_type         = "ELB"
  health_check_grace_period = 600
  force_delete              = true
  wait_for_capacity_timeout = "0"
  target_group_arns         = [aws_lb_target_group.clixx_web_tg.arn]

  tag {
    key                 = "Name"
    value               = "${title(var.project_name)}-Web-App"
    propagate_at_launch = true
  }
}

# Scale Up Policy (High CPU)
resource "aws_autoscaling_policy" "clixx_scale_up_policy" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.clixx_asg.name
}

# Scale Down Policy (Low CPU)
resource "aws_autoscaling_policy" "clixx_scale_down_policy" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.clixx_asg.name
}
