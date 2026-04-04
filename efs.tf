# ==========================================
# EFS Configuration
# ==========================================

resource "aws_efs_file_system" "clixx_efs" {
  creation_token   = "${var.project_name}-efs-${var.environment}"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.common_tags, {
    Name        = "${title(var.project_name)}-EFS"
    Application = "${title(var.project_name)} Web App"
  })
}

# EFS Mount Targets (one per public subnet for cross-AZ access)
resource "aws_efs_mount_target" "clixx_efs_mount" {
  for_each = aws_subnet.public_subnets

  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs_sg.id]
}
