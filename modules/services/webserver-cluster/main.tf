provider "aws" {
  region = "us-east-2"
}

# LAUNCH CONFIGURATION
# Use a launch configuration to set up an Auto Scaling Group. Requires launch configuration and aws_autoscaling_group defined as resources.
resource "aws_launch_configuration" "example" {
  image_id        = "ami-0fb653ca2d3203ac1"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" -> index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

  # Required when using a launch configuration with an auto scaling group
  # Creates the replacement resource first, then deletes the old resource
  lifecycle {
    create_before_destroy = true
  }
}

# AUTO SCALING GROUP
resource "aws_autoscaling_group" "example" {
  # what is the purpose of referencing the name value and where is it referencing it from?
  launch_configuration = aws_launch_configuration.example.name
  # references VPC subnet values. Since we're using a VPC with subnets, the subnets resource identifies them for use in our load balancer
  vpc_zone_identifier = data.aws_subnets.default.ids

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# APPLICATION LOAD BALANCER LISTENER
# Create an Application Load Balancer to create a shared location across the Auto Scaling Group. 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# APPLICATION LOAD BALANCER LISTENER RULE
# adds a listener rule that sends requests that match any path to the target group containing the ASG
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# TARGET GROUP FOR AUTO SCALING GROUP
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# APPLICATION LOAD BALANCER
resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# VPC DEFAULT DEFINITION
# Directs Terraform to the default VPC on my account
data "aws_vpc" "default" {
  default = true
}

# SINGLE SERVER HOSTING
# Sets up a single web server hosted on port 8080. 
# resource "aws_instance" "example" {
#     ami = "ami-0fb653ca2d3203ac1"
#     instance_type = "t2.micro"
#     vpc_security_group_ids = [aws_security_group.instance.id]

#     user_data = <<-EOF
#                 #!/bin/bash
#                 echo "Hello, World" -> index.html
#                 nohup busybox httpd -f -p ${var.server_port} &
#                 EOF

#     user_data_replace_on_change = true

#     tags = {
#         Name = "terraform-example"
#     }
# }

# APP LOAD BALANCER SECURITY GROUP
# Security group for ALB (Application Load Balancer) traffic
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SINGLE SERVER SECURITY GROUP
# Security group for 8080 traffic
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AUTO SCALING LOAD BALANCER HEALTH CHECK
# periodically sends health checks about the Auto Scaling Load Balancer
resource "aws_autoscaling_group" "example-health" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  # The default health check type is EC2 - which considers an Instance unhealthy is the VM is completely down or unreachable. 
  # ELB is more robust, and will replace the Instance if it's unhealthy (ex. Instances run out of memory or a critical process crashed)
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# REPLACE DNS FOR AUTO SCALING LOAD BALANCER
output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

