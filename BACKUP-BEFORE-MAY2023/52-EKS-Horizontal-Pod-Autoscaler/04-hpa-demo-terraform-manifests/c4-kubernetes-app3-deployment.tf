# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp3" {
  metadata {
    name = "app3-nginx-deployment"
    labels = {
      app = "app3-nginx"
    }
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
          image = "k8s.gcr.io/hpa-example"
          name  = "app3-nginx"
          port {
            container_port = 80
          }
          resources {
            limits = {
              cpu = "500m"
            }
            requests = {
              cpu = "200m"
            }
          }
          }
        }
      }
    }
}

