# Outputs file

output "aws_vpc_id" {
   value = "${aws_vpc.vpc.id}"
}

output "aws_websubnet1_id" {
   value = "${aws_subnet.web_subnet1.id}"
}

output "aws_websubnet2_id" {
   value = "${aws_subnet.web_subnet2.id}"
}

output "aws_web_sg1_id" {
   value = "${aws_security_group.web_sg1.id}"
}

output "aws_web_sg2_id" {
   value = "${aws_security_group.web_sg2.id}"
}

output "aws_db_subnet_grp_id" {
   value = "${aws_db_subnet_group.rds.id}"
}

output "aws_db_sg_id" {
   value = "${aws_security_group.rds.id}"
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