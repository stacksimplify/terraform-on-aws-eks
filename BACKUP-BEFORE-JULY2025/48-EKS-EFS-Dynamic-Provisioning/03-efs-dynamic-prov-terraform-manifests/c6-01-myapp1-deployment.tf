# Resource: UserMgmt WebApp Kubernetes Deployment
resource "kubernetes_deployment_v1" "myapp1" {
  depends_on = [ aws_efs_mount_target.efs_mount_target]
  metadata {
    name = "myapp1"
  }
   spec {
    replicas = 2
    selector {
      match_labels = {
        app = "myapp1"
      }
    }
    template {
      metadata {
        name = "myapp1-pod"
        labels = {
          app = "myapp1"
        }
      }
      spec {
        container {
          name  = "myapp1-container"
          image = "stacksimplify/kubenginx:1.0.0"
          port {
            container_port = 80
          }
          volume_mount {
            name = "persistent-storage"
            mount_path = "/usr/share/nginx/html/efs"
          }
        }
        volume {          
          name = "persistent-storage"
          persistent_volume_claim {
          claim_name = kubernetes_persistent_volume_claim_v1.efs_pvc.metadata[0].name 
        }
      }
    }
  }
}
}
