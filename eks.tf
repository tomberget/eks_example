data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

# Create cluster name
locals {
  cluster_name = "${var.cluster_name}-${var.environment}"
}

module "eks" {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs
  source                   = "terraform-aws-modules/eks/aws"
  version                  = "13.2.1"
  cluster_name             = local.cluster_name
  cluster_version          = var.cluster_version
  subnets                  = flatten([aws_subnet.default[*].id])
  vpc_id                   = aws_vpc.default.id
  attach_worker_cni_policy = true
  enable_irsa              = true

  tags = {
    createdby   = "terraform",
    environment = var.environment,
  }

  worker_groups = [
    {
      name                 = "wg-${local.cluster_name}"
      instance_type        = "t2.small"
      root_volume_size     = 20
      root_volume_type     = "gp2"
      
      spot_instance_pools      = var.spot_instance_pools
      spot_allocation_strategy = "lowest-price"
      
      asg_max_size         = var.asg_max_capacity
      asg_desired_capacity = var.asg_desired_capacity
      kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=spot"
      public_ip            = false
      # target_group_arns    = # A list of Application LoadBalancer (ALB) target group ARNs to be associated to the autoscaling group
    }
  ]
}
