# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "myapp3_np_service" {
  metadata {
    name = "app3-nginx-nodeport-service"
    annotations = {
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
      #"alb.ingress.kubernetes.io/healthcheck-path" = "/index.html"
    }    
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp3.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}
