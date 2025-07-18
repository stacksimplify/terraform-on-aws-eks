# Resource: Kubernetes Persistent Volume
resource "kubernetes_persistent_volume_v1" "efs_pv" {
  metadata {
    name = "efs-pv" 
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class_v1.efs_sc.metadata[0].name    
    persistent_volume_source {
      csi {
      driver = "efs.csi.aws.com"
      volume_handle = aws_efs_file_system.efs_file_system.id
      }
    }
  } 
} 

# Storage Size (storage = "5Gi")
## You can specify any size for the persistent volume in the storage field. 
## Kubernetes requires this field, but because Amazon EFS is an 
## elastic file system, it does not enforce any file system capacity. 