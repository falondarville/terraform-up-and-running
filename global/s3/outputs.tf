# Shows Terraform pulling the latest state from the S3 bucket then pushing the latest state
output "s3_bucket_arn" {
    value       = "aws_s3_bucket.terraform_state.arn"
    description = "The name of the DynamoDB table"
}

output "dynamodb_table_name" {
    value       = aws_dynamodb_table.terraform_locks.name
    description = "The name of the DynamoDB table"
}