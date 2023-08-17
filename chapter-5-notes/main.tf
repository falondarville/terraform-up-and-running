# This file contains notes on Chapter 5 "Loops, If-Statements, Deployment, and Gotchas"

# Add provider
provider "aws" {
  region = "us-east-2"
}

# Count through variable user_names and assign "name"
# The limitation of create IAM users this was is that any modification to the list will result in 
# replacement and deletion since it's done by index ordering. For example, manually deleting "Bob" will
# actually replace [0] with Jane and [1] with Buddy, and delete [2].
resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}

# Rather than the above way of create multiple users, you can use a for_each function with our
# same user_names variable. 
# This method allows you to safely remove values from anywhere in the collection.
resource "aws_iam_user" "example" {
  # convert the user_names list into a set since for_each only supports sets and maps
  for_each = toset(var.user_names)
  name     = each.value
}