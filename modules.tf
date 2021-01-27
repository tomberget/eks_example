module "nginx" {
  source        = "./modules/nginx"
  repository    = "https://kubernetes.github.io/ingress-nginx"
  chart_version = "3.21.0"

  domain_name = var.dns_zone_name

  depends_on = [module.eks.worker_groups]
}

module "external_dns" {
  source        = "./modules/external_dns"
  chart_version = "4.5.4"
  repository    = "https://charts.bitnami.com/bitnami"

  cluster_id             = module.eks.cluster_id
  external_dns_id        = "aws"
  external_dns_region    = var.aws_region
  external_dns_role_name = var.external_dns_role_name
  account_id             = data.aws_caller_identity.current.account_id
  txt_owner_id           = var.hostedzone_id

  depends_on = [module.eks.worker_groups]
}

module "cert_manager" {
  source        = "./modules/cert_manager"
  repository    = "https://charts.jetstack.io"
  chart_version = "v1.1.0"

  hostedzone_id        = var.hostedzone_id
  open_id_connect_arn  = module.eks.oidc_provider_arn
  identity_oidc_issuer = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  worker_iam_role_arn  = module.eks.worker_iam_role_arn
  account_id           = data.aws_caller_identity.current.account_id
  email                = var.email
  region               = var.aws_region
  dns_zone_name        = var.dns_zone_name

  depends_on = [module.eks.worker_groups]
}
