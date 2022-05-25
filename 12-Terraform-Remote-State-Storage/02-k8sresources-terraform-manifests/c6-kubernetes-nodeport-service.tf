# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "np_service" {
  metadata {
    name = "myapp1-nodeport-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
      node_port   = 31280
    }
    type = "NodePort"
  }
}
