# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp3" {
  metadata {
    name = "app3-nginx-deployment"
    labels = {
      app = "app3-nginx"
    }
    namespace = kubernetes_namespace_v1.ns_app3.metadata[0].name    
  } 
 
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app3-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app3-nginx"
        }
      }

      spec {
        container {
          image = "stacksimplify/kubenginx:1.0.0"
          name  = "app3-nginx"
          port {
            container_port = 80
          }
          }
        }
      }
    }
}

