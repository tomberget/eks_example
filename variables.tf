variable "environment" {
  description = "Specifies the environment used"
}

variable "aws_region" {
  description = "AWS Region to use"
  default     = "eu-west-1"
}

variable "cluster_name" {
  type = string
}

variable "asg_max_capacity" {
  type = number
}

variable "asg_desired_capacity" {
  type = number
}

variable "asg_min_capacity" {
  type = number
}

variable "spot_instance_pools" {
  type = number
}

variable "instance_type" {
  default     = "t2.small"
  description = "Type of EC2 instances to use"
}

variable "cluster_version" {
  description = "EKS Cluster version"
}

# setting txt owner id
variable "hostedzone_id" {
  type        = string
  description = "Hosted Zone ID for ExternalDNS and Cert Manager when using AWS Route53"
}

# setting external dns role name (and lets see how long I take to remove it)
variable "external_dns_role_name" {
  default     = "ExternalDNS"
  description = "IAM role name to use for accessing Route53"
}

variable "email" {
  type        = string
  description = "Email for Lets Encrypt certificates"
}

variable "dns_zone_name" {
  description = "DNS zone to use"
}

variable "dns_record_name" {
  description = "DNS record to use for the ALB"
}

variable "user_arn" {
  description = "User ARN to add to the cluster config map"
}

variable "user_name" {
  description = "User name to add to the cluster config map"
}
