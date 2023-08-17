# Create multiple users
# The limitation of create IAM users this was is that any modification to the list will result in 
# replacement and deletion since it's done by index ordering. For example, manually deleting "Bob" will
# actually replace [0] with Jane and [1] with Buddy, and delete [2].
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["Bob", "Jane", "Buddy"]
}
