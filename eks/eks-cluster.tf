resource "aws_eks_cluster" "eks_cluster" {
  name     = "${local.name}-${var.cluster_name}"
  role_arn = aws_iam_role.eks_master_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = module.vpc.public_subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access = var.cluster_endpoint_public_access
    public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController
  ]
}

resource "aws_eks_node_group" "eks_ng_public" {
  cluster_name = aws_eks_cluster.eks_cluster.name

  node_group_name = "${local.name}-eks-ng-public"
  node_role_arn = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids = module.vpc.public_subnets

  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = "eks-terraform-key"
  }

  scaling_config {
    desired_size = 1
    min_size = 1
    max_size = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "Public-Node-Group"
  }
}

resource "aws_eks_node_group" "eks_ng_private" {
  cluster_name = aws_eks_cluster.eks_cluster.name

  node_group_name = "${local.name}-eks-ng-private"
  node_role_arn = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids = module.vpc.private_subnets

  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = "eks-terraform-key"
  }

  scaling_config {
    desired_size = 1
    min_size = 1
    max_size = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "private-Node-Group"
  }
}

resource "aws_key_pair" "eks-terraform-key" {
  key_name = "eks-terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDPY5vGn6SelluRnbepfrjn+mEqmkjt7oVsySeuyhihmwlrk+0n+c3VQxAsx/UFo+I8lHOWtMd8hV2oxfU6Eia1Lcov9dCbsK82r/eFCqwdk9LbxBJLTTzYELpF/+jvaHkFtNGnZDU0Xnn3fUVYo1dPRSbjPeMQvO2RkVF/pQiIhR5i/sPjBMzlVrmZnfzntL39x0pGHz6/YsIja/2L0lx/MoRf5ApntLCPFtn+DNjYvYcgOnjVATvP1/Y5+1jMnK6jLaVyZqot0eW61gnG0FY7igr1nshnzbDH6ICqibk7+pKlMddbj2JzD2nHogMCWDy3DAF2kvsIllT4bNDGDRBkeTqncvJBOjRP8wauOhAM8qz83XvUCb8Py6ApDBIFOOWyB3xFxHdP2z8g5bgAH+WpsAVUMbqJr9i9pyFE+7K8i2em6D4IHtlDsTaGjmxj1Y+d51O5JaKzyhu2HSBS1DfF8vhhQbNjanWLlBPOFX9YacXkwm8mcvbhatYrixMir2s= m@kit"
}
