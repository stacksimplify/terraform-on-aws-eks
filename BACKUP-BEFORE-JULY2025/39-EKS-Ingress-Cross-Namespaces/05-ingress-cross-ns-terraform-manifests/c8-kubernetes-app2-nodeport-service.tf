# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "myapp2_np_service" {
  metadata {
    name = "app2-nginx-nodeport-service"
    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app2/index.html"
    }    
    namespace = kubernetes_namespace_v1.ns_app2.metadata[0].name    
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp2.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}
