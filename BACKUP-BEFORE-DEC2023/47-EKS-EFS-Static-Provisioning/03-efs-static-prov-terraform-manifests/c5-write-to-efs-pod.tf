# Resource: Kubernetes Pod - Write to EFS Pod
resource "kubernetes_pod_v1" "efs_write_app_pod" {
  depends_on = [ aws_efs_mount_target.efs_mount_target]  
  metadata {
    name = "efs-write-app"
  }
  spec {
    container {
      name  = "efs-write-app"
      image = "busybox"
      command = ["/bin/sh"]
      args = ["-c", "while true; do echo EFS Kubernetes Static Provisioning Test $(date -u) >> /data/efs-static.txt; sleep 5; done"]
      volume_mount {
        name = "persistent-storage"
        mount_path = "/data"
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