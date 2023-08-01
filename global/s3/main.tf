provider "aws" {
    region = "us-east-2"
}

# Create S3 bucket to store Terraform state
resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-up-and-running-state-falon"

    # Prevent accidental deletion of this S3 bucket
    # lifecycle {
    #     prevent_destroy = true
    # }
}

# Enable versioning so you can see the full revision history of your state files
resource "aws_s3_bucket_versioning" "enabled" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

# Enable server-side encryption by default for all data written to the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket                  = aws_s3_bucket.terraform_state.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# Create DynamoDB take to use for locking
resource "aws_dynamodb_table" "terraform_locks" {
    name            = "terraform-up-and-running-locks"
    billing_mode    = "PAY_PER_REQUEST"
    hash_key        = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

# State stored in S3 will not be able to read variables. State values need to be hard coded. Alternatively, I'm going to use a partial configuration.
# Settings (bucket, region, etc.) will be passed from a file via -backend-config arguments to 'terraform init'
# Sample command: 'terraform init -backend-config=backend.hcl'
# terraform {
#     backend "s3" {
#         key = "example/terraform.tfstate"
#     }
# }

# Deploy an EC2 instance to a Terraform Workspace
# Benefit of Terraform Workspace: allows you to work across multiple "environments"

# Establishes the DEFAULT Workspace. Use 'terraform workspace new name-example' to create a new workspace in the auto-created
# folder env:/
resource "aws_instance" "example" {
    ami             = "ami-0fb653ca2d3203ac1"
    # Set the DEFAULT Terraform Workspace to use a medium EC2 instance, and all subsequent Workspaces to MICRO
    # instance_type   = "t2.micro" # set all instances to use MICRO EC2 instance
    instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro" 
}
 
terraform {
    backend "s3" {
        bucket          = "terraform-up-and-running-state-falon"
        key             = "workspaces-example/terraform.tfstate"
        region          = "us-east-2"

        dynamodb_table  = "terraform-up-and-running-locks"
        encrypt         = true
    }
}