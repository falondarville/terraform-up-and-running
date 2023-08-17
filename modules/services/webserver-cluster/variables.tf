variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "alb_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}

# Chapter 5 for_each to add custom tags 
variable "custom_tags" {
  description = "Custom tags to set on the Instance in the ASG"
  default     = {}
}