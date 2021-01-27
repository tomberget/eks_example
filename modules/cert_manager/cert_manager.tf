resource "kubernetes_namespace" "cert_manager" {
  metadata {
    annotations = {
      name = var.cert_manager_namespace
    }

    name = var.cert_manager_namespace
  }
}

resource "helm_release" "cert_manager" {
  count = var.cert_manager_enabled ? 1 : 0

  name       = "cert-manager"
  repository = var.repository
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  timeout    = 1200

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt"
  }
}

resource "helm_release" "letsencrypt" {
  count = var.cert_manager_enabled ? 1 : 0

  name       = "cert-manager-letsencrypt-issuer"
  chart      = "${path.root}/charts/letsencrypt/"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  timeout    = 1200
  depends_on = [helm_release.cert_manager]

  set {
    name  = "acme.dns01.enabled"
    value = "True"
  }

  set {
    name  = "acme.dns01.dnsZones"
    value = var.dns_zone_name
  }

  set {
    name  = "acme.dns01.route53.region"
    value = var.region
  }

  set {
    name  = "acme.dns01.route53.hostedZoneID"
    value = var.hostedzone_id
  }

  set {
    name  = "acme.dns01.route53.role"
    value = aws_iam_role.cert_manager.arn
  }

  set {
    name  = "email"
    value = var.email
  }
}
