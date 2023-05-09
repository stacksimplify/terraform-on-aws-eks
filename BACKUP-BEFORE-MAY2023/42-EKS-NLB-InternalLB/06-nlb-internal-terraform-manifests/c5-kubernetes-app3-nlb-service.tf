# Kubernetes Service Manifest (Type: Network Load Balancer Service)
resource "kubernetes_service_v1" "myapp3_nlb_service" {
  metadata {
    name = "lbc-network-lb-internal"
    annotations = {
      # Traffic Routing
      "service.beta.kubernetes.io/aws-load-balancer-name" = "lbc-network-lb-internal"
      "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance" # specifies the target type to configure for NLB. You can choose between instance and ip
      #service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-xxxx, mySubnet ## Subnets are auto-discovered if this annotation is not specified, see Subnet Discovery for further details.
      
      # Health Check Settings
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "http"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port" = "traffic-port"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path" = "/index.html"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold" = 3
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold" = 3
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval" = 10 # The controller currently ignores the timeout configuration due to the limitations on the AWS NLB. The default timeout for TCP is 10s and HTTP is 6s.

      # Access Control
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal" # specifies whether the NLB will be internet-facing or internal
      # The VPC CIDR will be used if service.beta.kubernetes.io/aws-load-balancer-scheme is internal
      #"service.beta.kubernetes.io/load-balancer-source-ranges" = "0.0.0.0/0"  # specifies the CIDRs that are allowed to access the NLB.
      
      # AWS Resource Tags
      "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Environment=dev, Team=test"
    }        
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp3.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
