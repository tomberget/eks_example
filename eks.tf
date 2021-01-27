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
  subnets                  = flatten([aws_subnet.this.*.id])
  vpc_id                   = aws_vpc.this.id
  attach_worker_cni_policy = true
  enable_irsa              = true

  map_users = [
    {
      userarn  = var.user_arn
      username = var.user_name
      groups   = ["system:masters"]
    },
  ]

  tags = {
    createdby   = "terraform",
    environment = var.environment,
  }

  worker_groups = [
    {
      name          = "wg"
      instance_type = var.instance_type

      # Set values for spot instances
      kubelet_extra_args = "--node-labels=node.kubernetes.io/lifecycle=spot"

      # Set automatic scaling group values
      asg_max_size         = var.asg_max_capacity
      asg_desired_capacity = var.asg_desired_capacity
      asg_min_size         = var.asg_min_capacity

      # Set public IP
      public_ip = true

      # A list of Application LoadBalancer (ALB) target group ARNs to be associated to the autoscaling group
      target_group_arns = [aws_lb_target_group.this.arn]
    }
  ]
}
