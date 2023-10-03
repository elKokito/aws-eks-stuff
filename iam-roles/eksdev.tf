resource "aws_iam_role" "eksdev" {
  name = "${local.name}-eks-dev"

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
      }
    ]
  })

  inline_policy {
    name = "eks-dev"

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
        },
      ]
    })
  }

  tags = {
    tag-key = "${local.name}-eks-dev"
  }
}

resource "aws_iam_group" "eksdev" {
  name = "${local.name}-eksdev"
  path = "/"
}

resource "aws_iam_group_policy" "eksdev" {
  name  = "${local.name}-eksdev"
  group = aws_iam_group.eksdev.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Sid      = "AllowAssumOrganizationAccountRole"
      Resource = "${aws_iam_role.eksdev.arn}"
    }]
  })
}

resource "aws_iam_user" "eksdev" {
  name          = "${local.name}-eksdev"
  path          = "/"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_iam_group_membership" "eksdev" {
  name = "${local.name}-eksdev"
  users = [
    aws_iam_user.eksdev.name
  ]
  group = aws_iam_group.eksdev.name
}
