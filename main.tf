provider "aws" {
    region="ap-southeast-1"
}

# Variable section
variable "server_port" {
  description = "The port for HTTP request"
  type = number
}


# EC2 section
resource "aws_launch_configuration" "web" {
  image_id           = "ami-01581ffba3821cdf3"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.alb.id]
  user_data       = file("template/user_data.sh")

  lifecycle {
    # Create replacement first then destroy old ones
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  launch_configuration = aws_launch_configuration.web.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-experiment"
    propagate_at_launch = true
  } 
}

# AWS LB section
resource "aws_lb" "web" {
 name = "terraform-asg-experiment"
 load_balancer_type = "application"
 subnets = data.aws_subnet_ids.default.ids 
 security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404:page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terrafrom-asg-experiment"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# Security Group section
resource "aws_security_group" "alb" {
  name = "terraform-alb-experiment"

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    protocol = "tcp"
    from_port = 80
    to_port = 80
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    protocol = -1
    from_port = 0
    to_port = 0
  }
}


# Data section
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
