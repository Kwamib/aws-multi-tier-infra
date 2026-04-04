# ==========================================
# Core Network Outputs
# ==========================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.clixx_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for subnet in aws_subnet.public_subnets : subnet.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for subnet in aws_subnet.private_subnets : subnet.id]
}

output "private_subnet_map" {
  description = "Map of private subnet details by CIDR"
  value = {
    for k, v in local.private_subnets : k => {
      id                = aws_subnet.private_subnets[k].id
      cidr_block        = v.cidr_block
      availability_zone = v.availability_zone
      purpose           = v.purpose
      name              = v.name
    }
  }
}

# ==========================================
# Load Balancer Outputs
# ==========================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.clixx_lb.dns_name
}

output "target_group_arn" {
  description = "ARN of the web application target group"
  value       = aws_lb_target_group.clixx_web_tg.arn
}

# ==========================================
# Auto Scaling Group Outputs
# ==========================================

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.clixx_asg.name
}

# ==========================================
# EFS Output
# ==========================================

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.clixx_efs.dns_name
}

# ==========================================
# RDS Database Outputs
# ==========================================

output "rds_endpoint" {
  description = "Connection endpoint for the RDS database"
  value       = aws_db_instance.clixx_db_from_snapshot.endpoint
}

output "rds_port" {
  description = "Port the RDS database accepts connections on"
  value       = aws_db_instance.clixx_db_from_snapshot.port
}

# ==========================================
# Bastion Host Outputs
# ==========================================

output "bastion_info" {
  description = "Bastion host connection details"
  value = {
    az1 = {
      instance_id = aws_instance.bastion[0].id
      public_ip   = aws_instance.bastion[0].public_ip
      private_ip  = aws_instance.bastion[0].private_ip
    }
    az2 = {
      instance_id = aws_instance.bastion[1].id
      public_ip   = aws_instance.bastion[1].public_ip
      private_ip  = aws_instance.bastion[1].private_ip
    }
  }
}

# ==========================================
# Subnet Organization Outputs
# ==========================================

output "subnet_ids_by_purpose" {
  description = "Subnet IDs organized by purpose"
  value = {
    public = {
      for purpose in distinct([for k, v in local.public_subnets : v.purpose]) :
      purpose => [
        for k, v in aws_subnet.public_subnets : v.id if local.public_subnets[k].purpose == purpose
      ]
    }
    private = {
      for purpose in distinct([for k, v in local.private_subnets : v.purpose]) :
      purpose => [
        for k, v in aws_subnet.private_subnets : v.id if local.private_subnets[k].purpose == purpose
      ]
    }
  }
}

output "app_url" {
  description = "Application URL"
  value       = "https://${local.app_fqdn}"
}
