# Kubernetes Service Manifest (Type: Network Load Balancer Service)
resource "kubernetes_service_v1" "myapp3_nlb_service" {
  metadata {
    name = "extdns-tls-lbc-network-lb"
    annotations = {
      # Traffic Routing
      "service.beta.kubernetes.io/aws-load-balancer-name" = "extdns-tls-lbc-network-lb"
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
      "service.beta.kubernetes.io/load-balancer-source-ranges" = "0.0.0.0/0"  # specifies the CIDRs that are allowed to access the NLB.
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing" # specifies whether the NLB will be internet-facing or internal

      # AWS Resource Tags
      "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Environment=dev, Team=test"

      # TLS
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = "${aws_acm_certificate.acm_cert.arn}"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "443" # Specify this annotation if you need both TLS and non-TLS listeners on the same load balancer
      "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"

      # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "tfnlbdns101.stacksimplify.com"
    }        
  }
  spec {
    selector = {
      #app = kubernetes_deployment_v1.myapp3.spec.0.selector.0.match_labels.app  # Both representations are same "spec.0." or "spec[0]."
      app = kubernetes_deployment_v1.myapp3.spec[0].selector[0].match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    port {
      name        = "https"
      port        = 443
      target_port = 80
    }    
    type = "LoadBalancer"
  }
}
