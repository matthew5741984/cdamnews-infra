data "aws_availability_zones" "az" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Public Subnet 1
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_subnet1_cidr_block}"
  availability_zone       = "${data.aws_availability_zones.az.names[0]}"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.environment}-vpc-public_subnet1"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_subnet2" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_subnet2_cidr_block}"
  availability_zone       = "${data.aws_availability_zones.az.names[1]}"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.environment}-vpc-public_subnet2"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet1" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.private_subnet1_cidr_block}"
  availability_zone = "${data.aws_availability_zones.az.names[0]}"

  tags = {
    Name = "${var.environment}-vpc-private_subnet1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_subnet2" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.private_subnet2_cidr_block}"
  availability_zone = "${data.aws_availability_zones.az.names[1]}"

  tags = {
    Name = "${var.environment}-vpc-private_subnet2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${var.environment}-vpc-internet-gateway"
  }
}

# Elastic IP
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.igw"]
}

# Nat Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.public_subnet1.id}"
  depends_on    = ["aws_internet_gateway.igw"]

  tags = {
    Name = "${var.environment}-vpc-nat-gateway"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "${var.environment}-public_route_table"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }

  tags = {
    Name = "${var.environment}-private_route_table"
  }
}

# Route Table Association with Public Subnet
resource "aws_route_table_association" "with_public_subnet1" {
  subnet_id      = "${aws_subnet.public_subnet1.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "with_public_subnet2" {
  subnet_id      = "${aws_subnet.public_subnet2.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# Route Table Association with Private Subnet
resource "aws_route_table_association" "with_private_subnet1" {
  subnet_id      = "${aws_subnet.private_subnet1.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "with_private_subnet2" {
  subnet_id      = "${aws_subnet.private_subnet2.id}"
  route_table_id = "${aws_route_table.private.id}"
}
