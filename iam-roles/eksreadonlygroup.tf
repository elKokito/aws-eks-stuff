resource "aws_iam_role" "eksreadonly" {
  name = "${local.name}-eks-readonly"
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
    name = "eks-readonly-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "iam:ListRoles",
            "ssm:GetParameter",
            "eks:DescribeNodegroup",
            "eks:ListNodegroups",
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:AccessKubernetesApi",
            "eks:ListUpdates",
            "eks:ListFargateProfiles",
            "eks:ListIdentityProviderConfigs",
            "eks:ListAddons",
            "eks:DescribeAddonVersions"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    tag-key = "${local.name}-eks-reaonly-role"
  }
}

resource "aws_iam_group" "eksreadonly" {
  name = "${local.name}-eksreadonly"
  path = "/"
}

resource "aws_iam_group_policy" "eksreadonly" {
  name  = "${local.name}-eksreadonly"
  group = aws_iam_group.eksreadonly.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Sid      = "AllowAssumeOrganizationAccountRole"
        Resource = "${aws_iam_role.eksreadonly.arn}"
      },
    ]
  })
}

resource "aws_iam_user" "eksreadonly" {
  name          = "${local.name}-eksreadonly"
  path          = "/"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_iam_group_membership" "eksreadonly" {
  name = "${local.name}-eksreadonly"
  users = [
    aws_iam_user.eksreadonly.name
  ]
  group = aws_iam_user.eksreadonly.name
}
