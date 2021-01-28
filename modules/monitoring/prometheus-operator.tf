resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = var.namespace

    labels = {
      "istio-injection"    = "disabled"
      "kiali.io/member-of" = "istio-system"
    }
  }
}

data "google_secret_manager_secret_version" "alertmanager_slack_webhook" {
  secret = "alertmanager-slack-webhook"
}

data "template_file" "prometheus_operator_config" {
  template = file("${path.root}/modules/monitoring/config.yaml")
  vars = {
    istio_secret = var.istio_enabled ? "[istio.default, istio.prometheus-operator-prometheus]" : "[]"

    alertmanager_ingress_host    = "alertmanager.${var.ingress_host}"
    alertmanager_tls_secret_name = "alertmanager-${replace(var.ingress_host, ".", "-")}-tls"
    
    grafana_ingress_host    = "grafana.${var.ingress_host}"
    grafana_tls_secret_name = "grafana-${replace(var.ingress_host, ".", "-")}-tls"
    grafana_org_name        = var.grafana_org_name

    prometheus_operator_create_crd = true
    prometheus_ingress_host        = "prometheus.${var.ingress_host}"
    prometheus_tls_secret_name     = "prometheus-${replace(var.ingress_host, ".", "-")}-tls"
  }
}

resource "helm_release" "prometheus-operator" {
  name       = "prometheus-operator"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version

  values = [
    data.template_file.prometheus_operator_config.rendered
  ]
}
