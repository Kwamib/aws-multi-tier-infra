# ==========================================
# Local Variables
# ==========================================

locals {
  ami_id         = data.aws_ssm_parameter.clixx_ami.value
  ami_version    = var.ami_id != "" ? "manual" : try(data.aws_ssm_parameter.clixx_ami_version.value, "unknown")
  ami_build_date = var.ami_id != "" ? "manual" : try(data.aws_ssm_parameter.clixx_ami_build_date.value, "unknown")

  availability_zones  = slice(data.aws_availability_zones.available.names, 0, 2)
  account_id          = data.aws_caller_identity.current.account_id
  env_name_normalized = lower(replace(var.environment, " ", "-"))

  # FQDN for the application
  app_fqdn     = "${var.app_subdomain}.${var.domain_name}"
  app_fqdn_www = "www.${local.app_fqdn}"

  # Subnet purpose mapping
  subnet_purposes = {
    "10.0.0.0/23"   = "web"
    "10.0.2.0/23"   = "web"
    "10.0.4.0/24"   = "app1"
    "10.0.5.0/24"   = "app1"
    "10.0.6.0/24"   = "app2"
    "10.0.7.0/24"   = "app2"
    "10.0.8.0/24"   = "rds"
    "10.0.9.0/24"   = "rds"
    "10.0.10.0/24"  = "oracle"
    "10.0.11.0/24"  = "oracle"
    "10.0.12.0/26"  = "java"
    "10.0.12.64/26" = "java"
  }

  # Common resource tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Team        = var.team_name
    ManagedBy   = "terraform"
  }

  # Public subnet map with purpose-based names
  public_subnets = {
    for cidr in var.public_subnet_cidr : cidr => {
      cidr_block        = cidr
      availability_zone = lookup(var.az_mapping, cidr, var.default_az)
      type              = "public"
      purpose           = lookup(local.subnet_purposes, cidr, "misc")
      name              = "${title(var.project_name)}-Public-${lookup(local.subnet_purposes, cidr, "misc")}-${substr(lookup(var.az_mapping, cidr, var.default_az), -1, 1)}"
    }
  }

  # Private subnet map with purpose-based names
  private_subnets = {
    for cidr in var.private_subnet_cidr : cidr => {
      cidr_block        = cidr
      availability_zone = lookup(var.az_mapping, cidr, var.default_az)
      type              = "private"
      purpose           = lookup(local.subnet_purposes, cidr, "misc")
      name              = "${title(var.project_name)}-Private-${lookup(local.subnet_purposes, cidr, "misc")}-${substr(lookup(var.az_mapping, cidr, var.default_az), -1, 1)}"
    }
  }

  # Bastion host subnet IDs
  bastion_subnets = [
    aws_subnet.public_subnets["10.0.0.0/23"].id,
    aws_subnet.public_subnets["10.0.2.0/23"].id
  ]
}
