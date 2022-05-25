# Resource: Kubernetes Storage Class
resource "kubernetes_storage_class_v1" "ebs_sc" {  
  metadata {
    name = "ebs-sc"
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
}