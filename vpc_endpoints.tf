# ==========================================
# VPC Endpoint for EFS
# ==========================================

resource "aws_vpc_endpoint" "efs" {
  vpc_id            = aws_vpc.clixx_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.elasticfilesystem"
  vpc_endpoint_type = "Interface"

  # One subnet per AZ to avoid duplicate ENI errors
  subnet_ids = [
    aws_subnet.private_subnets["10.0.4.0/24"].id,
    aws_subnet.private_subnets["10.0.5.0/24"].id
  ]

  security_group_ids  = [aws_security_group.efs_sg.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${title(var.project_name)}-EFS-VPC-Endpoint"
  })
}

# ==========================================
# EFS Access Point
# ==========================================

resource "aws_efs_access_point" "clixx_efs_ap" {
  file_system_id = aws_efs_file_system.clixx_efs.id

  root_directory {
    path = "/app"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = merge(local.common_tags, {
    Name = "${title(var.project_name)}-EFS-AccessPoint"
  })
}
