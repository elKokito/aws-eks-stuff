variable "environment" {
  type    = string
  default = "lol"
}

variable "business_divsion" {
  type    = string
  default = "money"
}

variable "cluster_name" {
  type    = string
  default = "eks_cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.27"
}

variable "cluster_endpoint_private_access" {
  type = bool
  default = false
}

variable "cluster_endpoint_public_access" {
  type = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type = list
}

variable "cluster_service_ipv4_cidr" {
  type = string
}
