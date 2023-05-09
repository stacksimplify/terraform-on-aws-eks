# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "vpa_demo_app" {
  metadata {
    name = "vpa-demo-deployment" 
    labels = {
      app = "vpa-nginx"
    }
  } 
 
  spec {
    replicas = 4

    selector {
      match_labels = {
        app = "vpa-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "vpa-nginx"
        }
      }

      spec {
        container {
          image = "stacksimplify/kubenginx:1.0.0"
          name  = "vpa-nginx"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu = "5m"
              memory = "5Mi"
            }
          }
          }
        }
      }
    }
}

