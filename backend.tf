# ==========================================
# Terraform Remote Backend Configuration
# ==========================================
# Stores state in S3 with DynamoDB locking for CI/CD safety.
# Update bucket and table names in your environment.

terraform {
  backend "s3" {
    bucket         = "REPLACE-WITH-YOUR-STATE-BUCKET"
    key            = "clixx/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "REPLACE-WITH-YOUR-LOCK-TABLE"
    encrypt        = true
  }
}
