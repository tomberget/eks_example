# Define terraform version to use
terraform {
  required_version = "~> 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Create the provider
provider "aws" {
}

# Create variable
variable "environment" {
  description = "The environment to create in: dev, test, stage, prod"
}

# Create a random Id, used for creating a Globally unique name
resource "random_uuid" "bucket_postfix" {
}

# create a bucket for remote state file
resource "aws_s3_bucket" "bucket" {
  bucket = "tf-remote-state-eks-example-${var.environment}-${substr(random_uuid.bucket_postfix.result, 29, 6)}"
  acl    = "private"

  tags = {
    created_by  = "terraform"
    purpose     = "eks-example"
    environment = var.environment
  }

  versioning {
    enabled = true
  }
}

# Block all public access for S3 bucket
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "dynamodb_terraform_state_lock" {
  name           = aws_s3_bucket.bucket.bucket
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    created_by  = "terraform"
    purpose     = "devops-training-example"
    environment = var.environment
  }

  depends_on = [aws_s3_bucket.bucket]
}
