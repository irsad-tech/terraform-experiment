provider "aws" {
    region="ap-southeast-1"
}

variable "server_port" {
  description = "The port for HTTP request"
  type = number
  default = 80
}

resource "aws_instance" "web" {

  ami           = "ami-01581ffba3821cdf3"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ssh_http.name]
  user_data       = file("template/user_data.sh")
  monitoring = true

  tags = {
    "Name" = "ubuntu-web"
  }
}

resource "aws_security_group" "ssh_http" {
  name        = "ssh_http"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
