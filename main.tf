provider "aws" {
    region = "us-east-2"
}

# Use a launch configuration to set up an Auto Scaling Group. Requires launch configuration and aws_autoscaling_group defined as resources.
resource "aws_launch_configuration" "example" {
    image_id = "ami-0fb653ca2d3203ac1"
    instance_type = "t2.micro"
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

resource "aws_autoscaling_group" "example" {
    # what is the purpose of referencing the name value and where is it referencing it from?
    launch_configuration = aws_launch_configuration.example.name
    # references VPC subnet values. Since we're using a VPC with subnets, the subnets resource identifies them for use in our load balancer
    vpc_zone_identifier = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

# Directs Terraform to the default VPC on my account
data "aws_vpc" "default" {
    default = true
}

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

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}