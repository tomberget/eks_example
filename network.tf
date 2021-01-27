# Create a VPC
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.this.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# A security group for the ELB so it is accessible via the VM
resource "aws_security_group" "this" {
  description = "Allow connection between ALB and target"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "ingress" {
  security_group_id = aws_security_group.this.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_availability_zones" "this" {
}

# Create a subnet to launch our instances into
resource "aws_subnet" "this" {
  count = var.asg_max_capacity

  availability_zone       = data.aws_availability_zones.this.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  vpc_id                  = aws_vpc.this.id
  map_public_ip_on_launch = false

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

# Create an Application Load Balancer
resource "aws_lb" "this" {
  name               = "alb-${var.cluster_name}"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.this.*.id

  enable_cross_zone_load_balancing = true

  tags = {
    "createdby"   = "terraform",
    "environment" = var.environment,
  }
}

# The ALB target group
resource "aws_lb_target_group" "this" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  depends_on = [
    aws_lb.this
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# The ALB listener
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Set up Route53
data "aws_route53_zone" "this" {
  name = var.dns_zone_name
}

resource "aws_route53_record" "this" {
  name = var.dns_record_name
  type = "CNAME"

  records = [
    aws_lb.this.dns_name,
  ]

  zone_id = data.aws_route53_zone.this.zone_id
  ttl     = "60"
}

# Create an ACME certificate
resource "aws_acm_certificate" "this" {
  domain_name       = "${var.dns_record_name}.${var.dns_zone_name}"
  validation_method = "DNS"

  tags = {
    createdby   = "terraform",
    environment = "test",
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Set up the certificate validation
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [aws_route53_record.web_cert_validation.fqdn]

  lifecycle {
    create_before_destroy = true
  }
}

# Validate the certificate
resource "aws_route53_record" "web_cert_validation" {
  name = sort(aws_acm_certificate.this.domain_validation_options[*].resource_record_name)[0]
  type = sort(aws_acm_certificate.this.domain_validation_options[*].resource_record_type)[0]

  records = flatten([aws_acm_certificate.this.domain_validation_options.*.resource_record_value])

  zone_id = data.aws_route53_zone.this.id
  ttl     = 60

  lifecycle {
    create_before_destroy = true
  }
}
