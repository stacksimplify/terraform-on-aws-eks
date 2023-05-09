# Resource: MySQL Cluster IP Service
resource "kubernetes_service_v1" "mysql_clusterip_service" {
  metadata {
    name = "mysql"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.mysql_deployment.spec.0.selector.0.match_labels.app 
    }
    port {
      port        = 3306 # Service Port
      #target_port = 3306 # Container Port  # Ignored when we use cluster_ip = "None"
    }
    type = "ClusterIP"
    cluster_ip = "None" # This means we are going to use Pod IP   
  }
}