resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"

    labels = {
      name        = "jenkins"
      description = "jenkins"
    }
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "4.1.13"
  namespace  = "jenkins"
  timeout    = 600
  values = [
    file("jenkins-helm-values.yaml"),
  ]

  depends_on = [
    kubernetes_namespace.jenkins,
    google_compute_region_ssl_certificate.default,
  ]
}
