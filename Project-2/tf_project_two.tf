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



# Create vpc

variable "vpc_cidr" {
  description = "cidr block for vpc"
  default     = "10.0.0.0/24"
  # type = string 
}
resource "aws_vpc" "p2_vpc" {
  cidr_block  = var.vpc_cidr

  tags = {
    Name = "p2"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "p2_igw" {
  vpc_id = aws_vpc.p2_vpc.id

  tags = {
    Name = "p2"
  }
}

# Create Custom Route Table

resource "aws_route_table" "p2_rt" {
  vpc_id = aws_vpc.p2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.p2_igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.p2_igw.id
  }

  tags = {
    Name = "p2"
  }
}

# Create a Subnet

resource "aws_subnet" "p2_subnet" {
  vpc_id     = aws_vpc.p2_vpc.id
  cidr_block = "10.0.1.128/25"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "p2"
  }
}

# Associate subnet with Route Table

resource "aws_route_table_association" "p2_rta" {
  subnet_id      = aws_subnet.p2_subnet.id
  route_table_id = aws_route_table.p2_rt.id
}

# Create Security Group to allow port 22,80,443

resource "aws_security_group" "p2_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.p2_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "p2"
  }
}

# Create a network interface with an ip in the subnet
# private ip

resource "aws_network_interface" "p2_eni" {
  subnet_id       = aws_subnet.p2_subnet.id
  private_ips     = ["10.0.1.15"]
  security_groups = [aws_security_group.p2_sg.id]
  tags = {
    Name = "p2"
  }

}

# Assign elastic IP to the network interface
# public ip

resource "aws_eip" "p2_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.p2_eni.id
  associate_with_private_ip = "10.0.1.15"
  depends_on = [ aws_internet_gateway.p2_igw ]
  tags = {
    Name = "p2"
  }
}

# Create Ubuntu server and install/enable apache2

resource "aws_instance" "p2_ins" {
  ami           = "ami-01a00762f46d584a1"
  instance_type = "t2.micro"
  key_name      = "demo-key"
  
  primary_network_interface {
    network_interface_id = aws_network_interface.p2_eni.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl enable apache2
              sudo systemctl start apache2
              sudo bash -c 'echo "<h1>Welcome to Terraform Project 2</h1>" > /var/www/html/index.html'
              EOF
  tags = {
    Name = "p2"
  }
}



output "ami_id" {
  description = "AMI ID"
  value = aws_instance.p2_ins.ami
}

output "az" {
  description = "Availability Zone"
  value = aws_instance.p2_ins.availability_zone
}

output "cidr_block" {
  description = "CIDR block of the VPC"
  value = aws_vpc.p2_vpc.cidr_block
}

output "security_groups" {
  description = "Security group ID"
  value = aws_security_group.p2_sg.id
}