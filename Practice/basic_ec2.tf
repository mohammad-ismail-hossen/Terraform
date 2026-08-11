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
  access_key = "~access_key~"
  secret_key = "~secret_key~"
}


resource "aws_instance" "ec2_instance1" {
  ami           = "ami-0884624fc54d115f3"
  instance_type = "t2.micro"
  tags = {
    Name = "demo"
  }
}