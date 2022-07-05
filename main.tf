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

# This external module encapsulates the VPC/Subnet creation similar to what we did earlier.
# Modules are great for code reuse.
module "scwlua-NotasComplicatedApp-NetworkModule" {
  source  = "app.terraform.io/scwlua-test/scwlua-NotasComplicatedApp-NetworkModule/aws"
  version = "1.0.0"
   region = var.region
   prefix = "scwlua"
   tags = {
    Name        = "scwlua-vpc-${var.region}"
    Environment = "development"
  }
}