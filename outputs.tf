# Outputs file

output "aws_vpc_id" {
   value = "${module.scwlua-NotasComplicatedApp-NetworkModule.aws_vpc_id}"
}

output "aws_websubnet1_id" {
   value = "${module.scwlua-NotasComplicatedApp-NetworkModule.aws_websubnet1_id}"
}

output "aws_websubnet2_id" {
   value = "${module.scwlua-NotasComplicatedApp-NetworkModule.aws_websubnet2_id}"
}

output "aws_web_sg1_id" {
   value = "${module.scwlua-NotasComplicatedApp-NetworkModule.aws_web_sg1_id}"
}

output "aws_web_sg2_id" {
   value = "${module.scwlua-NotasComplicatedApp-NetworkModule.aws_web_sg2_id}"
}

output "aws_db_subnet_grp_id" {
   value = "${module.scwlua-NotasComplicatedApp-NetworkModule.aws_db_subnet_grp_id}"
}

output "aws_db_sg_id" {
   value = "${module.scwlua-NotasComplicatedApp-NetworkModule.aws_db_sg_id}"
}

#output "aws_vpc_id" {
#  value = "${module.scwlua-webapp-networking.vpc_id}"
#}

#output "aws_subnet_id" {
#  value = "${module.scwlua-webapp-networking.subnet_id}"
#}

#output "aws_security_group_id" {
#  value = "${module.scwlua-webapp-networking.vpc_security_group_ids}"
#}