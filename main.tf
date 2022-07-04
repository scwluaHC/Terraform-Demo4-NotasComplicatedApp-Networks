provider "aws" {
  region = var.region
}

## DEPLOYMENT PORTION TO AWS ##
# VPC PORTION #
# Define VPC, name pull from var
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = var.vpc_name
    Environment = "test"
  }
}

# Create web subnets - public

resource "aws_subnet" "web_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones_1
  tags = {
    Name = var.pub_subnet1
  }
}

resource "aws_subnet" "web_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones_2
  tags = {
    Name = var.pub_subnet2
  }
}

# Create web sg 1
resource "aws_security_group" "web_sg1" {
  name        = "SG for Instance"
  description = "Terraform example security group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.web_sg1
  }
}

# Create web sg 2
resource "aws_security_group" "web_sg2" {
  name        = "SG2 for Instance"
  description = "Terraform example security group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.web_sg2
  }
}

# Creating an Internet Gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.ig_name
  }
}

# Add route to Internet Gateway
resource "aws_route" "route" {
  depends_on             = [aws_internet_gateway.gateway]
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

# DATABASE RELATED #
# Create RDS private subnets
resource "aws_subnet" "rds_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones_1 # [x] is the list position in var
  tags = {
    Name = var.rds_subnet1
  }
}

resource "aws_subnet" "rds_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones_2 # [x] is the list position in var
  tags = {
    Name = var.rds_subnet2
  }
}

# Create rds subnet group using 1 & 2 created
resource "aws_db_subnet_group" "rds" {
  depends_on = [aws_subnet.rds_subnet1, aws_subnet.rds_subnet2]
  name       = "main"
  subnet_ids = ["${aws_subnet.rds_subnet1.id}", "${aws_subnet.rds_subnet2.id}"]
  tags = {
    Name = var.rds_subnet_grp
  }
}

# Create RDS security group for SSH and MYSQL connection in the VPC using web_sgs 1 & 2
resource "aws_security_group" "rds" {
  depends_on  = [aws_security_group.web_sg1, aws_security_group.web_sg2]
  name        = "mysqlallow"
  description = "ssh allow to the mysql"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "ssh"
    security_groups = ["${aws_security_group.web_sg1.id}", "${aws_security_group.web_sg2.id}"]
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
  }
  ingress {
    description     = "MYSQL"
    security_groups = ["${aws_security_group.web_sg1.id}", "${aws_security_group.web_sg2.id}"]
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.sg_for_rds
  }
}