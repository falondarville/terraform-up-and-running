# This file contains notes on Chapter 4

# Add provider
provider "aws" {
  region = "us-east-2"
}

# Count through variable user_names and assign "name"
resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}