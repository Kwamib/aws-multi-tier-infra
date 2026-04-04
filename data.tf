# ==========================================
# Core AWS Data Sources
# ==========================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required", "opted-in"]
  }
}

# ==========================================
# IAM Data Sources
# ==========================================

data "aws_iam_instance_profile" "engineer" {
  name = "EngineerProfile"
}

# ==========================================
# ACM Certificate
# ==========================================

data "aws_acm_certificate" "clixx_cert" {
  domain      = "*.${var.domain_name}"
  statuses    = ["ISSUED"]
  most_recent = true
}

# ==========================================
# RDS Snapshot
# ==========================================

data "aws_db_snapshot" "clixx_snapshot" {
  db_snapshot_identifier = var.snapshot_identifier
  most_recent            = true
}

# ==========================================
# SSM Parameters (Cross-Account AMI Lookup)
# ==========================================

data "aws_ssm_parameter" "clixx_ami" {
  name     = var.ssm_ami_parameter
  provider = aws.ssm
}

data "aws_ssm_parameter" "clixx_ami_version" {
  name     = "${var.ssm_ami_parameter}/version"
  provider = aws.ssm
}

data "aws_ssm_parameter" "clixx_ami_build_date" {
  name     = "${var.ssm_ami_parameter}/build-date"
  provider = aws.ssm
}

# ==========================================
# ASG Instance Lookup
# ==========================================

data "aws_autoscaling_groups" "clixx_asg" {
  names      = [aws_autoscaling_group.clixx_asg.name]
  depends_on = [aws_autoscaling_group.clixx_asg]
}

data "aws_instances" "clixx_asg_instances" {
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  filter {
    name   = "instance.group-name"
    values = [data.aws_autoscaling_groups.clixx_asg.names[0]]
  }

  depends_on = [aws_autoscaling_group.clixx_asg]
}

# ==========================================
# Public Subnet Lookup
# ==========================================

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.clixx_vpc.id]
  }

  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}
