# ==========================================
# Application Load Balancer
# ==========================================

resource "aws_lb" "clixx_lb" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-lb"
  })
}

# HTTP → HTTPS Redirect
resource "aws_lb_listener" "clixx_listener" {
  load_balancer_arn = aws_lb.clixx_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "clixx_listener_https" {
  load_balancer_arn = aws_lb.clixx_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.clixx_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clixx_web_tg.arn
  }
}

# Target Group
resource "aws_lb_target_group" "clixx_web_tg" {
  name        = var.target_group_name
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  vpc_id      = aws_vpc.clixx_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck.html"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = var.target_group_name
  })
}
