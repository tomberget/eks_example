resource "helm_release" "nginx" {
  name       = "nginx"
  namespace  = "kube-system"
  repository = var.repository
  chart      = var.chart_name
  version    = var.chart_version

  values = [
    data.template_file.nginx_config.rendered
  ]
}

data "template_file" "nginx_config" {
  template = file("${path.root}/modules/nginx/config.yaml")

  vars = {
    domain_name = var.domain_name
  }
}
