# Define the provider
provider "aws" {
  region = "us-east-1"
}


# Create VPC 
data "aws_vpc" "main" {
  default = true
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}


# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Local variables
locals {
  default_tags = merge(module.globalvars.default_tags, { "env" = var.env })
  prefix       = module.globalvars.prefix
  prefix_main  = "${local.prefix}-${var.env}"
}
module "globalvars" {
  source = "../../../globalvars"
}


# Create First EC2/Webserver
resource "aws_instance" "webapp" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = lookup(var.type, var.env)
  key_name      = aws_key_pair.web_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.prefix_main}-webapp"
    }
  )
}



# Adding SSH key for EC2/Webserver
resource "aws_key_pair" "webappkey" {
  key_name   = local.prefix_main
  public_key = file("${local.prefix_main}.pub")
}


# Security Group For webapp
resource "aws_security_group" "web_sg" {
  name        = "Webserver traffic Dockers/EC2"
  description = "Webserver traffic Dockers/EC2"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP from everyone"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "SSH from everyone"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.prefix_main}-web_sg"
    }
  )
}

# Repositry for Web App
resource "aws_ecr_repository" "webapp" {
  name                 = "webapp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Repositry for my SQl

resource "aws_ecr_repository" "db_mysql" {
  name                 = "db_mysql"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}