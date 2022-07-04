# Optionally define the settings for each provider and the backend
#terraform {
#  backend "consul" {
#    address  = "192.168.126.128:8500"
#    scheme   = "http"
#    path     = "operatortf/terraform.tfstate"
#    lock     = true
#    gzip     = false
#  }
#}

#data "terraform_remote_state" "admin" {
#  backend = "local"
#  config = {
#    path = var.path
#  }
#}

#data "terraform_remote_state" "admin" {
#  backend = "consul"
#  config = {
#    address  = "192.168.126.128:8500"
#    scheme   = "http"
#    path     = "vaultadmintf/terraform.tfstate"
#  }
#}

#data "vault_aws_access_credentials" "creds" {
#  backend = data.terraform_remote_state.admin.outputs.backend
#  role    = data.terraform_remote_state.admin.outputs.role
#}

provider "aws" {
  profile = "default"
  region  = var.region
  #  access_key = data.vault_aws_access_credentials.creds.access_key
  # secret_key = data.vault_aws_access_credentials.creds.secret_key
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
  }
}

# Create web subnets - public

resource "aws_subnet" "web_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[0]
  tags = {
    Name = var.pub_subnet1
  }
}

resource "aws_subnet" "web_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[1]
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
  availability_zone       = var.availability_zones[0] # [x] is the list position in var
  tags = {
    Name = var.rds_subnet1
  }
}

resource "aws_subnet" "rds_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones[1] # [x] is the list position in var
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

# Setup the RDS options group
resource "aws_db_option_group" "rds" {
  name                     = "optiongroup-test-terraform"
  option_group_description = "Terraform Option Group"
  engine_name              = "mysql"
  major_engine_version     = "5.7"
  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT"
    }
    option_settings {
      name  = "SERVER_AUDIT_FILE_ROTATIONS"
      value = "37"
    }
  }
}

# Create DB param group
resource "aws_db_parameter_group" "rds" {
  name   = "rdsmysql"
  family = "mysql5.7"
  parameter {
    name  = "autocommit"
    value = "1"
  }
  parameter {
    name  = "binlog_error_action"
    value = "IGNORE_ERROR"
  }
}

# Create DB instance
resource "aws_db_instance" "rds" {
  depends_on             = [aws_db_subnet_group.rds, aws_db_option_group.rds, aws_security_group.rds, aws_db_parameter_group.rds]
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = var.database_name
  username               = var.database_user
  password               = var.database_password
  db_subnet_group_name   = aws_db_subnet_group.rds.id
  option_group_name      = aws_db_option_group.rds.id
  publicly_accessible    = "false"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  parameter_group_name   = aws_db_parameter_group.rds.id
  skip_final_snapshot    = true
  tags = {
    Name = var.db_instance_name
  }
}

# EC2 RELATED #
# Create EC2 Instance
resource "aws_instance" "app_server" {
  depends_on                           = [aws_security_group.web_sg1, aws_security_group.web_sg2, aws_subnet.web_subnet1, aws_subnet.web_subnet2, aws_db_instance.rds]
  ami                                  = var.amis[var.region]
  instance_type                        = "t2.micro"
  associate_public_ip_address          = true
  vpc_security_group_ids               = ["${aws_security_group.web_sg1.id}", "${aws_security_group.web_sg2.id}"]
  subnet_id                            = aws_subnet.web_subnet2.id
  user_data                            = templatefile("user_data.tftpl", { rds_endpoint = "${aws_db_instance.rds.endpoint}", user = var.database_user, password = var.database_password, dbname = var.database_name })
  instance_initiated_shutdown_behavior = "terminate"
  root_block_device {
    volume_type = "gp2"
    volume_size = "15"
  }
  tags = {
    Name = var.instance_name
  }
}

# Create an AMI based on the EC2 instance app_server
resource "aws_ami_from_instance" "ec2_image" {
  # added aws_alb.alb to depends_on
  depends_on         = [aws_instance.app_server, aws_alb.alb]
  name               = "demo-ami"
  source_instance_id = aws_instance.app_server.id
}

# Create autoscaling launch config
resource "aws_launch_configuration" "ec2" {
  depends_on      = [aws_security_group.web_sg1, aws_security_group.web_sg2, aws_ami_from_instance.ec2_image]
  image_id        = aws_ami_from_instance.ec2_image.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.web_sg1.id}", "${aws_security_group.web_sg2.id}"]
  lifecycle {
    create_before_destroy = true
  }
}

# Create autoscaling group
resource "aws_autoscaling_group" "ec2" {
  depends_on           = [aws_subnet.web_subnet2, aws_subnet.web_subnet1, aws_launch_configuration.ec2]
  launch_configuration = aws_launch_configuration.ec2.id
  min_size             = 2
  max_size             = 3
  target_group_arns    = ["${aws_alb_target_group.group.arn}"]
  vpc_zone_identifier  = ["${aws_subnet.web_subnet2.id}", "${aws_subnet.web_subnet1.id}"]
  health_check_type    = "EC2"
}

# LB RELATED #
# Create ALB SG
resource "aws_security_group" "alb" {
  name        = "terraform_alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.alb_sg
  }
}

# Create ALB
resource "aws_alb" "alb" {
  depends_on      = [aws_subnet.web_subnet2, aws_subnet.web_subnet1, aws_security_group.alb, aws_alb_target_group.group, aws_instance.app_server]
  name            = "terraform-example-alb"
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["${aws_subnet.web_subnet2.id}", "${aws_subnet.web_subnet1.id}"]
  tags = {
    Name = var.alb_name
  }
}

# Create ALB target group
resource "aws_alb_target_group" "group" {
  depends_on = [aws_vpc.vpc]
  name       = "terraform-example-alb-target"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.vpc.id
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page, consider remove.
  health_check {
    path = "/"
    port = 80
  }
}

# Create ALB listener for http
resource "aws_alb_listener" "listener_http" {
  depends_on        = [aws_alb.alb]
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}

output "ip" {
  value = aws_instance.app_server.public_ip
}

output "lb_address" {
  value = aws_alb.alb.dns_name
}

#output "awsaccess" {
#  value = "${data.vault_aws_access_credentials.creds.access_key}"
#}

#output "awssecret" {
#  value = "${data.vault_aws_access_credentials.creds.secret_key}"
#}