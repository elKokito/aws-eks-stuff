variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "cluster_name" {
  type    = string
  default = "kity"
}

variable "environment" {
  type    = string
  default = "hammar"
}

locals {
  environment = var.environment
  name        = var.environment
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    environment = local.environment
  }
  made_by_terraform = true
  eks_cluster_name  = "${var.cluster_name}-${var.environment}"
}
