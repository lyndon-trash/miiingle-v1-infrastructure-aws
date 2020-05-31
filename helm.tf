resource "kubernetes_service_account" "tiller" {
  depends_on = [module.eks_cluster]
  metadata {
    name = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  depends_on = [module.eks_cluster]
  metadata {
    name = "tiller"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
  subject {
    kind = "ServiceAccount"
    namespace = "kube-system"
    name = "tiller"
  }
}

resource "helm_release" "kube-utils" {
  depends_on = [kubernetes_cluster_role_binding.tiller, kubernetes_service_account.tiller]
  chart = "../infrastructure-helm/kube-utils"
  name = "kube-utils"
}

resource "helm_release" "backend" {
  depends_on = [helm_release.kube-utils]
  chart = "../infrastructure-helm/backend"
  name = "backend"
}