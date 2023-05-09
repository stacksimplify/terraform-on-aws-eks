# Resource: UserMgmt WebApp Kubernetes Deployment
resource "kubernetes_deployment_v1" "usermgmt_webapp" {
  depends_on = [kubernetes_deployment_v1.mysql_deployment]
  metadata {
    name = "usermgmt-webapp"
    labels = {
      app = "usermgmt-webapp"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "usermgmt-webapp"
      }
    }
    template {
      metadata {
        labels = {
          app = "usermgmt-webapp"
        }
      }
      spec {
        container {
          image = "stacksimplify/kube-usermgmt-webapp:1.0.0-MySQLDB"
          name  = "usermgmt-webapp"
          #image_pull_policy = "always"  # Defaults to Always so we can comment this
          port {
            container_port = 8080
          }
          env {
            name = "DB_HOSTNAME"
            #value = "mysql"
            value = kubernetes_service_v1.mysql_clusterip_service.metadata.0.name 
          }
          env {
            name = "DB_PORT"
            #value = "3306"
            value = kubernetes_service_v1.mysql_clusterip_service.spec.0.port.0.port
          }
          env {
            name = "DB_NAME"
            value = "webappdb"
          }
          env {
            name = "DB_USERNAME"
            value = "root"
          }
          env {
            name = "DB_PASSWORD"
            #value = "dbpassword11"
            value = kubernetes_deployment_v1.mysql_deployment.spec.0.template.0.spec.0.container.0.env.0.value
          }          
        }
      }
    }
  }
}
