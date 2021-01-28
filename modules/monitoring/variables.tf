variable "ingress_host" {}

variable "istio_enabled" {
  default = false
}

variable "grafana_org_name" {
  default = "Main Org."
}

variable "namespace" {}
variable "chart_version" {}
