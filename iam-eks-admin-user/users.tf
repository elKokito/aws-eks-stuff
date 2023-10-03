data "aws_caller_identity" "current" {}

locals {
  configmap_roles = [
    {
      rolearn  = "${aws_iam_role.eks_nodegroup_role.arn}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "${aws_iam_role.eks_admin_role.arn}"
      username = "eks-admin"
      groups   = ["system:masters"]
    }
  ]
}

resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [aws_eks_cluster.eks_cluster]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(local.configmap_roles)
  }
}

resource "aws_iam_role" "eks_admin_role" {
  name = "${local.name}-eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
  inline_policy {
    name = "eks-full-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "iam:ListRoles",
            "eks:*",
            "ssm:GetParameter"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = {
    tag-key = "${local.name}-eks-admin-role"
  }
}

resource "aws_iam_group" "eksadmins" {
  name = "${local.name}-eksadmins"
  path = "/"
}

resource "aws_iam_group_policy" "eksadmins" {
  name  = "${local.name}-eks-admin-group-policy"
  group = aws_iam_group.eksadmins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect   = "Allow"
        Sid      = "AllowAssumeOrganizationAccountRole"
        Resource = "${aws_iam_role.eks_admin_role.arn}"
      },
    ]
  })
}

resource "aws_iam_user" "eksadmin" {
  name          = "${local.name}-eksadmin"
  path          = "/"
  force_destroy = true
  tags          = local.common_tags
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

resource "aws_iam_group_membership" "eksadmins" {
  name = "${local.name}-eksadmins-group-membership"
  users = [
    aws_iam_user.eksadmin.name
  ]
  group = aws_iam_group.eksadmins.name
}

