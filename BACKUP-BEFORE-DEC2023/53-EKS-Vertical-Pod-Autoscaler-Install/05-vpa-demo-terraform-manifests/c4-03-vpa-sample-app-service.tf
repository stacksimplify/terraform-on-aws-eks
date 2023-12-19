# Kubernetes Service Manifest (Type: Cluster IP Service)
resource "kubernetes_service_v1" "myapp3_cip_service" {
  metadata {
    name = "vpa-demo-service-nginx" 
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.vpa_demo_app.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}
