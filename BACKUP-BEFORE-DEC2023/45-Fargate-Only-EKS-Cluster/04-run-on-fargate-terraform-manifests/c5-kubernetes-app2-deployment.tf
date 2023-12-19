# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp2" {
  metadata {
    name = "app2-nginx-deployment"
    namespace = "fp-ns-app1"        
    labels = {
      app = "app2-nginx"
    }
  } 
 
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app2-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app2-nginx"
        }
      }

      spec {
        container {
          image = "stacksimplify/kube-nginxapp2:1.0.0"
          name  = "app2-nginx"
          port {
            container_port = 80
          }
          }
        }
      }
    }
}

