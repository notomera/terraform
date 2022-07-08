terraform {
  backend "s3" {
    profile = "prod"
    key = "global/s3/terraform.tfstate"
  }
}

provider "aws" {
  profile = "prod"
  region  = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-hive-mind"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_hive-mind_versioning" {
  bucket = aws_s3_bucket.terraform_state.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_hive-mind_encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-hive-mind"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.hive_test.id]
  }
}