# ==========================================
# Launch Template for Web Application
# ==========================================

resource "aws_launch_template" "clixx_web_app" {
  name_prefix = "${var.project_name}-web-app"
  description = "Launch template for ${title(var.project_name)} web application"
  image_id    = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  depends_on = [
    aws_subnet.public_subnets,
    aws_ssm_parameter.db_endpoint
  ]

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = element(values(aws_subnet.private_subnets), 0).id
    security_groups             = [aws_security_group.asg_sg.id]
  }

  iam_instance_profile {
    name = data.aws_iam_instance_profile.engineer.name
  }

  user_data = base64encode(
    templatefile("${path.module}/userdata.sh", {
      EFS_ID            = aws_efs_file_system.clixx_efs.dns_name
      MOUNT_POINT       = var.mount_point
      ENVIRONMENT       = var.environment
      ENVIRONMENT_LOWER = local.env_name_normalized
      REGION            = var.aws_region
      DB_HOST           = aws_db_instance.clixx_db_from_snapshot.endpoint
    })
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name        = "${title(var.project_name)}-Web-Instance"
      Application = "${title(var.project_name)} Web App"
      AMI_ID      = local.ami_id
      AMI_Version = local.ami_version
      AMI_Source  = var.ami_id != "" ? "manual" : "ssm"
    })
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 10
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size           = 10
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  block_device_mappings {
    device_name = "/dev/sdc"
    ebs {
      volume_size           = 8
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  block_device_mappings {
    device_name = "/dev/sdd"
    ebs {
      volume_size           = 10
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  block_device_mappings {
    device_name = "/dev/sde"
    ebs {
      volume_size           = 10
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }
}
