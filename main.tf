provider "aws" {
  region = var.region
}

# This external module encapsulates the VPC/Subnet creation similar to what we did earlier.
# Modules are great for code reuse.
module "scwlua-NotasComplicatedApp-NetworkModule" {
  source  = "app.terraform.io/scwlua-test/scwlua-NotasComplicatedApp-NetworkModule/aws"
  version = "1.0.0"
   region = var.region
   tags = {
    Department = "e-sevices"
    Billable = "Yes"
  }
}