resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${local.name}-autoscaler"
  path = "/"
  description = "EKS auto scaler policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "autoscaling:*",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeInstanceTypes"
      ]
      Resource = "*"
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })

  tags = {
    "tag-key" = "cluster-autoscaler"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role = aws_iam_role.cluster_autoscaler.name
}

resource "helm_release" "cluster_autoscaler" {
  depends_on = [ aws_iam_role.cluster_autoscaler ]
  name = "${local.name}-cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"

  namespace = "kube-system"

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }
}
