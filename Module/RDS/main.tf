# Get latest snapshot from production DB
data "aws_db_snapshot" "db_snapshot" {
    most_recent = true
    db_instance_identifier = "${var.environment}-db"
}

# RDS Subnet Groups
resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = ["${var.private_subnet1}", "${var.private_subnet2}"]

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

# RDS Configuration
resource "aws_db_instance" "db" {
  allocated_storage       = "${var.dballocated_storage}"
  storage_type            = "${var.dbstorage_type}"
  engine                  = "${var.dbengine}"
  engine_version          = "${var.dbversion}"
  instance_class          = "${var.dbinstancetype}"
  name                    = "${var.dbname}"
  username                = "${var.dbusername}"
  password                = "${var.dbpassword}"
  parameter_group_name    = "${var.dbparameter_group_name}"
  db_subnet_group_name    = "${aws_db_subnet_group.db-subnet-group.id}"
  multi_az                = "${var.dbmulti_az}"
  publicly_accessible     = "${var.dbpublicly_accessible}"
  vpc_security_group_ids  = ["${var.db_sg_id}"]
  identifier              = "${var.environment}-db"
  snapshot_identifier  = "${data.aws_db_snapshot.db_snapshot.id}"
  skip_final_snapshot     = "${var.dbskip_final_snapshot}"
}
