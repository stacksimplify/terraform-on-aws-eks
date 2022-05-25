# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp3" {
  metadata {
    name = "app3-nginx-deployment"
    namespace = "fp-ns-app1"        
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
          image = "stacksimplify/kubenginx:1.0.0"
          name  = "app3-nginx"
          port {
            container_port = 80
          }
          resources {
            requests = {
              "cpu" = "1000m"
              "memory" = "2048Mi" 
            }
            limits = {
              "cpu" = "2000m"
              "memory" = "4096Mi"
            }
          }
          }
        }
      }
    }
}

## Reference about Capacity (https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html)
# The additional memory reserved for the Kubernetes components can cause a 
# Fargate task with more vCPUs than requested to be provisioned. 
# For example, a request for 1 vCPU and 8 GB memory will have 256 MB 
# added to its memory request, and will provision a Fargate task with 
# 2 vCPUs and 9 GB memory, since no task with 1 vCPU and 9 GB memory is 
# available.
# Requested: 1 vCPU + 8GB Memory
# Allocated: 2 vCPUs + 9GB Memory

