# Output ARNs for each IAM user when using the count method of IAM user creation
output "all_arns" {
  value       = "aws_iam_user.example[*].arn"
  description = "The ARNs for all users"
}

# Output ARNs and other creation info for each IAM user using the for_each method of IAM user creation
output "all_users" {
  value = aws_iam_user.example
}
# To print out just the ARNs when using for_each, use the following method.
output "all_arns" {
  value = values(aws_iam_user.example)[*].arn
}
