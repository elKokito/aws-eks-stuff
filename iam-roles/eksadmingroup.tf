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
        Action   = "sts:AssumeRole"
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

resource "aws_iam_group_membership" "eksadmins" {
  name = "${local.name}-eksadmins-group-membership"
  users = [
    aws_iam_user.eksadmin.name
  ]
  group = aws_iam_group.eksadmins.name
}

