variable "ingress_host" {}

variable "istio_enabled" {
  default = false
}

variable "grafana_org_name" {
  default = "Main Org."
}

variable "prometheus_namespace" {}
variable "prometheus_operator_chart_version" {}
