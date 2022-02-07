provider "aws" {}

variable "az" {}
variable "vpc_cidr_block" {}
variable "sn_cidr_block" {}
variable "env" {}

# creating vpc

resource "aws_vpc" "my-vpc" {
cidr_block = var.vpc_cidr_block
tags = {
       Name = "${var.env}-vpc"
       }
}

# creating subnet

resource "aws_subnet" "pubsub-1" {
vpc_id = aws_vpc.my-vpc.id
cidr_block = var.sn_cidr_block
tags = {
       Name = "${var.env}-subnet"
      }
}

# creating internet gate way

resource "aws_internet_gateway" "my-igw" {
vpc_id = aws_vpc.my-vpc.id
tags = {
       Name = "${var.env}-igw"
       }
}

# creating route table

resource "aws_route_table" "my-rtbl" {
vpc_id = aws_vpc.my-vpc.id
    route {
           cidr_block = "0.0.0.0/0"
           gateway_id = aws_internet_gateway.my-igw.id
          }
    tags = {
           Name = "${var.env}-rtbl"
           }
}

# creating route table subnet association

resource "aws_route_table_association" "rtbl-as-subnet" {
subnet_id = aws_subnet.pubsub-1.id
route_table_id = aws_route_table.my-rtbl.id
}

# creating security groups

resource "aws_security_group" "my-sg" {
name = "my-sg"
vpc_id = aws_vpc.my-vpc.id

ingress {
   from_port     = 22
   to_port       = 22
   protocol      = "tcp"
   cidr_blocks    =["0.0.0.0/0"]
}

ingress { 
  from_port     = 8080
  to_port       = 8080
  protocol      = "tcp"
  cidr_blocks    = ["0.0.0.0/0"]
  prefix_list_ids = []
}

tags = {
       Name = "${var.env}-sg"
       }
}

# creating ami image

data "aws_ami" "amazon-linux-image" {
most_recent = true
owners = ["amazon"]

filter {
name = "name"
values = ["amzn2-ami-hvm-*-x86_64-gp2"]
}

filter {
name = "virtualization-type"
values = ["hvm"]
}
}


# display output ami id 

output "ami_id" {
value = data.aws_ami.amazon-linux-image.id
}


# creating ec2-instance 

resource "aws_instance" "my-server" {
ami                                  = data.aws_ami.amazon-linux-image.id
instance_type                        = "t2.micro"
key_name                             = "jenkins-slave"
associate_public_ip_address          = true
subnet_id                            = aws_subnet.pubsub-1.id
vpc_security_group_ids               = [aws_security_group.my-sg.id]
availability_zone                    = var.az

tags = {
        Name = "${var.env}-server"
       }
}

# creating user data

