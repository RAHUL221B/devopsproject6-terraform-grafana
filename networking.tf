locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_id" "random" {

  byte_length = 2

}

resource "aws_vpc" "ans_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {

    Name = "ans_vpc-${random_id.random.dec}"

  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "ans_igw" {
  vpc_id = aws_vpc.ans_vpc.id

  tags = {
    Name = "ans_igw-${random_id.random.dec}"
  }
}

resource "aws_route_table" "ans_route_public" {

  vpc_id = aws_vpc.ans_vpc.id

  tags = {
    Name = "ans_route_public"
  }

}

resource "aws_route" "default_route" {

  route_table_id         = aws_route_table.ans_route_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ans_igw.id

}

resource "aws_default_route_table" "ans_route_private" {

  default_route_table_id = aws_vpc.ans_vpc.default_route_table_id

  tags = {
    Name = "ans_route_private"
  }

}

resource "aws_subnet" "ans_public_subnet" {
  count                   = length(var.public_cidr)
  cidr_block              = var.public_cidr[count.index]
  vpc_id                  = aws_vpc.ans_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "ans_public_subnet-${count.index + 1}"
  }

}

resource "aws_subnet" "ans_private_subnet" {

  count                   = length(var.private_cidr)
  cidr_block              = var.private_cidr[count.index]
  vpc_id                  = aws_vpc.ans_vpc.id
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "ans_private_subnet-${count.index + 1}"
  }

}
resource "aws_route_table_association" "ans_public_assoc" {

  count          = length(var.public_cidr)
  subnet_id      = aws_subnet.ans_public_subnet[count.index].id
  route_table_id = aws_route_table.ans_route_public.id

}

resource "aws_security_group" "ans_sg" {
  name        = "public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.ans_vpc.id

}

resource "aws_security_group_rule" "ingress_all" {


  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.access_ip]
  security_group_id = aws_security_group.ans_sg.id
}

resource "aws_security_group_rule" "egress_all" {

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ans_sg.id

}