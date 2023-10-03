resource "aws_iam_role" "irsa_iam_role" {
  name = "${local.name}-irsa-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:sub" : "system:serviceaccount:default:irsa-demo-sa"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "${local.name}-irsa-iam-role"
  }
}

data "aws_iam_policy" "AmazonS3ReadOnlyAccess" {
  name = "AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "irsa_iam_role_policy_attachment" {
  policy_arn = data.aws_iam_policy.AmazonS3ReadOnlyAccess.arn
  role       = aws_iam_role.irsa_iam_role.name
}

resource "kubernetes_service_account_v1" "irsa_demo_sa" {
  depends_on = [aws_iam_role_policy_attachment.irsa_iam_role_policy_attachment]
  metadata {
    name = "irsa-demo-sa"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_iam_role.arn
    }
  }
}


# Example of a job/pod using permission to read s3
resource "kubernetes_job_v1" "irsa_demo" {
  metadata {
    name = "irsa-demo"
  }
  spec {
    template {
      metadata {
        labels = {
          app = "irsa-demo"
        }
      }
      spec {
        service_account_name = kubernetes_service_account_v1.irsa_demo_sa.metadata.0.name
        container {
          name  = "irsa-demo"
          image = "amazon/aws-cli:latest"
          args  = ["s3", "ls"]
        }
        restart_policy = "Never"
      }
    }
  }
}
