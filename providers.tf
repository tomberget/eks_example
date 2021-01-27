terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  # rather than defining this inline, the credentials have been sourced
  # from Environment Variables - more information available below:
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables
  # 
  # note that region is also set by default by the $AWS_DEFAULT_REGION Environmental Variable.
}

provider "random" {
}

provider "local" {
}

provider "null" {
}

provider "template" {
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  # load_config_file       = false
}

provider "helm" {
  kubernetes {
    # load_config_file       = false
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}