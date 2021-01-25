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

variable "node_count" {
  type = number
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

variable "domain_name" {
  description = "Domain name to use"
}
