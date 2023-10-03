# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-marcial"
    key    = "hello-kitty/eks-cluster-irsa/terraform.tfstate"
    region = "us-west-1"

    # For State Locking
    dynamodb_table = "irsa"
  }
}

# Terraform Provider Block
provider "aws" {
  region = var.aws_region
}


data "aws_eks_cluster_auth" "auth" {
  name = var.cluster_name
}
provider "kubernetes" {
  host = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.auth.token
}
