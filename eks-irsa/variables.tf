variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  type    = string
  default = "kity"
}

variable "cluster_name" {
  type    = string
  default = "eks"
}

locals {
  environment = var.environment
  name        = var.environment
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    environment = local.environment
  }
  eks_cluster_name = "${var.cluster_name}-${var.environment}"
}
