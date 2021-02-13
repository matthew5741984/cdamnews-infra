# VPC Variable
variable "environment" {}

variable "vpc_cidr_block" {
    default = "10.0.0.0/16"
}

variable "public_subnet1_cidr_block" {
    default = "10.0.1.0/24"
}

variable "public_subnet2_cidr_block" {
    default = "10.0.2.0/24"
}

variable "private_subnet1_cidr_block" {
    default = "10.0.3.0/24"
}

variable "private_subnet2_cidr_block" {
    default = "10.0.4.0/24"
}
