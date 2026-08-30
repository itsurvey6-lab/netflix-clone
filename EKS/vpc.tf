module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs = local.azs

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  intra_subnets   = local.intra_subnets

  enable_dns_hostnames = true
  enable_nat_gateway   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/netflix-cluster" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/netflix-cluster" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }

  tags = local.tags
}