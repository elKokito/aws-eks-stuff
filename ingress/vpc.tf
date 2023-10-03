# Create VPC Terraform Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  #version = "3.11.0"
  #version = "~> 3.11"
  version = "~>5.1.0"

  # VPC Basic Details
  name            = local.name
  cidr            = "10.0.0.0/16"
  azs             = data.aws_availability_zones.available.names
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # Database Subnets
  database_subnets                   = ["10.0.151.0/24", "10.0.152.0/24"]
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  # create_database_internet_gateway_route = true
  # create_database_nat_gateway_route = true

  # NAT Gateways - Outbound Communication
  enable_nat_gateway = true
  single_nat_gateway = true

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags     = local.common_tags
  vpc_tags = local.common_tags

  # Additional Tags to Subnets
  public_subnet_tags = {
    Type                                              = "Public Subnets"
    "kubernetes.io/role/elb"                          = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    Type                                              = "private-subnets"
    "kubernetes.io/role/internal-elb"                 = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  database_subnet_tags = {
    Type = "database-subnets"
  }
  # Instances launched into the Public subnet should be assigned a public IP address.
  map_public_ip_on_launch = true
}
