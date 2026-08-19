terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  profile    = "aws-profile"
}


resource "aws_vpc" "first_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "fvpc"
  }
}

variable "subnet_prefix" {
  description = "cidr block for the subnet"
  default     = "10.0.1.0/24"
}

resource "aws_subnet" "first_subnet" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = var.subnet_prefix

  tags = {
    Name = "fsbnet"
  }
}

data "aws_security_group" "default_sg" {
  name   = "default"
  vpc_id = aws_vpc.first_vpc.id
}

resource "aws_instance" "first_instance" {
  ami           = "ami-0884624fc54d115f3"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.first_subnet.id
  vpc_security_group_ids = [data.aws_security_group.default_sg.id]
}

output "ec2_id" {
  value = aws_instance.first_instance.id
}

output "vpc_id" {
  value = aws_vpc.first_vpc.id
}

output "subnet_id" {
  value = aws_subnet.first_subnet.id
}