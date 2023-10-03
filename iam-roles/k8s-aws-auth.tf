data "aws_caller_identity" "current" {}

resource "kubernetes_cluster_role_v1" "eksreadonly" {
  metadata {
    name = "${local.name}-eksreadonly"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "pods", "events", "services"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "eksreadonly" {
  metadata {
    name = "${local.name}-eksreadonly"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.eksreadonly.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "eks-readonly"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role_v1" "eksdev_role" {
  metadata {
    name      = "${local.name}-eksdev-role"
    namespace = kubernetes_namespace_v1.k8s_dev.metadata[0].name
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding_v1" "eksdev_role" {
  metadata {
    name      = "${local.name}-eksdev-role"
    namespace = kubernetes_namespace_v1.k8s_dev.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.eksdev_role.metadata[0].name
  }
  subject {
    kind      = "Group"
    name      = "eksdev-role"
    api_group = "rbac.authorization.k8s.io"
  }
}

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
    },
    {
      rolearn  = "${aws_iam_role.eksreadonly.arn}",
      username = "eks-readonly"
      groups   = [kubernetes_cluster_role_binding_v1.eksreadonly.subject[0].name]
    },
    {
      rolearn  = "${aws_iam_role.eksdev.arn}"
      username = "eksdev"
      groups   = [kubernetes_role_binding_v1.eksdev_role.subject[0].name]
    },
  ]
}

resource "kubernetes_namespace_v1" "k8s_dev" {
  metadata {
    name = "dev"
  }
}

resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [
    aws_eks_cluster.eks_cluster,
    kubernetes_cluster_role_binding_v1.eksreadonly,
    kubernetes_role_binding_v1.eksdev_role
  ]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(local.configmap_roles)
  }
}

