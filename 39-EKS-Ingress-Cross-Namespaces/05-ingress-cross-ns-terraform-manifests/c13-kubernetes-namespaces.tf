# Resource: Kubernetes Namespace ns-app1
resource "kubernetes_namespace_v1" "ns_app1" {
  metadata {
    name = "ns-app1"
  }
}

# Resource: Kubernetes Namespace ns-app2
resource "kubernetes_namespace_v1" "ns_app2" {
  metadata {
    name = "ns-app2"
  }
}

# Resource: Kubernetes Namespace ns-app3
resource "kubernetes_namespace_v1" "ns_app3" {
  metadata {
    name = "ns-app3"
  }
}