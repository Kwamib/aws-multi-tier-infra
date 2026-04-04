# ==========================================
# Core AWS Configuration
# ==========================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "clixx"
}

variable "owner_email" {
  description = "Email address for resource ownership tagging"
  type        = string
}

variable "team_name" {
  description = "Team name for resource tagging"
  type        = string
  default     = "platform-engineering"
}

variable "assume_role_arn" {
  description = "IAM role ARN to assume for resource provisioning"
  type        = string
}

variable "domain_name" {
  description = "Base domain name for Route 53 and ACM (e.g., example.com)"
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain for the application (e.g., app)"
  type        = string
  default     = "clixx"
}

# ==========================================
# VPC and Subnet Configuration
# ==========================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.0.0/23", # Web Tier AZ-A (512 hosts)
    "10.0.2.0/23"  # Web Tier AZ-B (512 hosts)
  ]
}

variable "private_subnet_cidr" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.4.0/24",  # App Tier 1 AZ-A  (256 hosts)
    "10.0.5.0/24",  # App Tier 1 AZ-B  (256 hosts)
    "10.0.6.0/24",  # App Tier 2 AZ-A  (256 hosts)
    "10.0.7.0/24",  # App Tier 2 AZ-B  (256 hosts)
    "10.0.8.0/24",  # Database RDS AZ-A (256 hosts)
    "10.0.9.0/24",  # Database RDS AZ-B (256 hosts)
    "10.0.10.0/24", # Oracle DB AZ-A   (256 hosts)
    "10.0.11.0/24", # Oracle DB AZ-B   (256 hosts)
    "10.0.12.0/26", # Java App AZ-A    (64 hosts)
    "10.0.12.64/26" # Java App AZ-B    (64 hosts)
  ]
}

variable "az_mapping" {
  description = "Maps each subnet CIDR to its availability zone"
  type        = map(string)
  default = {
    "10.0.0.0/23"   = "us-east-1a"
    "10.0.2.0/23"   = "us-east-1b"
    "10.0.4.0/24"   = "us-east-1a"
    "10.0.5.0/24"   = "us-east-1b"
    "10.0.6.0/24"   = "us-east-1a"
    "10.0.7.0/24"   = "us-east-1b"
    "10.0.8.0/24"   = "us-east-1a"
    "10.0.9.0/24"   = "us-east-1b"
    "10.0.10.0/24"  = "us-east-1a"
    "10.0.11.0/24"  = "us-east-1b"
    "10.0.12.0/26"  = "us-east-1a"
    "10.0.12.64/26" = "us-east-1b"
  }
}

variable "default_az" {
  description = "Default availability zone fallback"
  type        = string
  default     = "us-east-1a"
}

# ==========================================
# EC2 Instance Configuration
# ==========================================

variable "ami_id" {
  description = "AMI ID for EC2 instances (leave empty to use latest from SSM)"
  type        = string
  default     = ""
}

variable "ami_version" {
  description = "AMI version to use from SSM (latest or specific version)"
  type        = string
  default     = "latest"
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair for EC2 access"
  type        = string
}

variable "trusted_ssh_cidr" {
  description = "CIDR block for trusted SSH access (restrict to your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

# ==========================================
# Auto Scaling Configuration
# ==========================================

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 3
}

# ==========================================
# Load Balancer Configuration
# ==========================================

variable "target_group_name" {
  description = "Name of the ALB target group"
  type        = string
  default     = "clixx-web-tg"
}

variable "target_group_port" {
  description = "Port the target group listens on"
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol used by the target group"
  type        = string
  default     = "HTTP"
}

# ==========================================
# EFS Configuration
# ==========================================

variable "mount_point" {
  description = "EFS mount point directory on EC2 instances"
  type        = string
  default     = "/var/www/html"
}

# ==========================================
# RDS Configuration
# ==========================================

variable "snapshot_identifier" {
  description = "RDS snapshot identifier to restore the database from"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.m6g.large"
}

# ==========================================
# Bastion Host Configuration
# ==========================================

variable "bastion_ami" {
  description = "AMI ID for bastion hosts (defaults to Amazon Linux 2)"
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  description = "Instance type for bastion hosts"
  type        = string
  default     = "t2.micro"
}

# ==========================================
# Monitoring Configuration
# ==========================================

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

# ==========================================
# SSM Configuration
# ==========================================

variable "ssm_ami_parameter" {
  description = "SSM parameter path for the latest AMI ID"
  type        = string
  default     = "/clixx/ami/latest"
}
