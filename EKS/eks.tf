module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  # EKS cluster
  cluster_name    = local.name
  cluster_version = "1.33"

  cluster_endpoint_public_access = true

  # EKS addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }
  }

  # Use our VPC
  vpc_id = module.vpc.vpc_id

  # Put EKS nodes in private subnets
  subnet_ids = module.vpc.private_subnets

  # Worker nodes
  eks_managed_node_groups = {
    nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t2.small"]
    }
  }

  # Tags
  tags = local.tags
}