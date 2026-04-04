# ==========================================
# AWS Provider Configuration
# ==========================================

# Provider for SSM parameters (cross-account access)
provider "aws" {
  alias  = "ssm"
  region = var.aws_region
}

# Provider for main infrastructure
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = var.assume_role_arn
  }
}
