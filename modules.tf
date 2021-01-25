module "external_dns" {
  source                     = "./modules/external_dns"
  cluster_id                 = module.eks.cluster_id
  external_dns_id            = "aws"
  external_dns_region        = var.aws_region
  external_dns_chart_version = "4.5.4"
  external_dns_role_name     = var.external_dns_role_name
  account_id                 = data.aws_caller_identity.current.account_id
  txt_owner_id               = var.hostedzone_id
}

module "cert_manager" {
  source                     = "./modules/cert_manager"
  cert_manager_chart_version = "v1.1.0"
  hostedzone_id              = var.hostedzone_id
  open_id_connect_arn        = aws_iam_openid_connect_provider.default.arn
  identity_oidc_issuer       = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  worker_iam_role_arn        = module.eks.worker_iam_role_arn
  account_id                 = data.aws_caller_identity.current.account_id
  email                      = var.email
  region                     = var.aws_region
  domain_name                = var.domain_name
}
