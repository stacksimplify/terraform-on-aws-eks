# Resource: Kubernetes Service Manifest (Type: Load Balancer - Classic)
resource "kubernetes_service_v1" "lb_service" {
  metadata {
    name = "usermgmt-webapp-lb-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.usermgmt_webapp.spec.0.selector.0.match_labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}