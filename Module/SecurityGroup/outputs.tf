#-------SecurityGroup/outputs.tf
output "elb_sg_id" {
  value = "${aws_security_group.elb_sg.id}"
}
output "app_sg_id" {
  value = "${aws_security_group.app_sg.id}"
}
output "db_sg_id" {
  value = "${aws_security_group.db_sg.id}"
}
