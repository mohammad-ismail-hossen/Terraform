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

data "aws_security_group" "launch_wizard_1" {
  name = "launch-wizard-1"
  vpc_id = "vpc-0ac5d6eb0f165b7fd"
}

resource "aws_instance" "demo1" {
  ami           = "ami-00d2dbb426772b03a"
  instance_type = "t3.micro"
  vpc_security_group_ids = [data.aws_security_group.launch_wizard_1.id]
}