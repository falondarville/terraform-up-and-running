# Assign multiple users variable
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["Bob", "Jane", "Buddy"]
}

