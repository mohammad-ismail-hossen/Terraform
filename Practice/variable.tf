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