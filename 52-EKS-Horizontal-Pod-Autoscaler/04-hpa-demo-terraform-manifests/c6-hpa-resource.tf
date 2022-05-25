# Resource: Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "hpa_myapp3" {
  metadata {
    name = "hpa-app3"
  }
  spec {
    max_replicas = 10
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.myapp3.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}