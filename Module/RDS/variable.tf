# VPC Variable
variable "environment" {}

variable "private_subnet1" {}

variable "private_subnet2" {}

# RDS Variable
variable "dballocated_storage" {
    default = 20
}

variable "dbstorage_type" {
    default = "gp2"
}

variable "dbengine" {
    default = "mysql"
}

variable "dbversion" {
    default = "8.0.20"
}

variable "dbinstancetype" {
    default = "db.t2.micro"
}

variable "dbname" {}

variable "dbusername" {}

variable "dbpassword" {}

variable "dbparameter_group_name" {
    default = "default.mysql8.0"
}

variable "dbmulti_az" {
    default = "false"
}

variable "dbpublicly_accessible" {
    default = "true"
}

variable "dbskip_final_snapshot" {
    default = "true"
}

# SecurityGroup Variable
variable "db_sg_id" {}
