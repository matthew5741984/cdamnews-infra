# VPC Variable
variable "environment" {}

variable "private_subnet1" {}

variable "private_subnet2" {}

# SecurityGroup Variable
variable "app_sg_id" {}

# RDS Variable
variable "db_instance" {}

# TaskExecution Image Variable
variable "image" {}

# Auto Scaling Variable
variable "ecs_as_cpu_high_threshold_per" {
    default = "80"
}
variable "ecs_as_cpu_low_threshold_per" {
    default = "20"
}

# ECS logs Variable
variable "awslogs_region" {}

# LoadBalancer Variable
variable "load_balancer_target_group_arn" {}
