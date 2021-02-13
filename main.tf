provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

module "Networking" {
  source = "./Module/Networking"
  environment = "${var.environment}"
}

module "SecurityGroup" {
  source = "./Module/SecurityGroup"
  environment = "${var.environment}"
  vpc_id = module.Networking.vpc_id
}

module "RDS" {
  source = "./Module/RDS"
  environment = "${var.environment}"
  private_subnet1 = module.Networking.private_subnet1
  private_subnet2 = module.Networking.private_subnet2
  db_sg_id = module.SecurityGroup.db_sg_id
  dbname = "${var.dbname}"
  dbusername = "${var.dbusername}"
  dbpassword = "${var.dbpassword}"
}

module "LoadBalancer" {
  source = "./Module/LoadBalancer"
  environment = "${var.environment}"
  vpc_id = module.Networking.vpc_id
  public_subnet1 = module.Networking.public_subnet1
  public_subnet2 = module.Networking.public_subnet2  
  elb_sg_id = module.SecurityGroup.elb_sg_id
}

module "ECS" {
  source = "./Module/ECS"
  environment = "${var.environment}"
  awslogs_region = "${var.region}"
  image = "${var.image}"
  load_balancer_target_group_arn = module.LoadBalancer.load_balancer_target_group_arn
  private_subnet1 = module.Networking.private_subnet1
  private_subnet2 = module.Networking.private_subnet2
  app_sg_id = module.SecurityGroup.app_sg_id
  db_instance = module.RDS.db_instance
}
