# Create a VPC
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# A security group for the ELB so it is accessible via the VM
resource "aws_security_group" "elb" {
  name        = "sec_group_elb_${var.environment}"
  description = "ELB Security Group"
  vpc_id      = aws_vpc.default.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_availability_zones" "available" {
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  count = var.asg_max_capacity

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.default.id
  map_public_ip_on_launch = false

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}
