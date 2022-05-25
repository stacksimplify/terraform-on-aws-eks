# Kubernetes Curl Pod for Internal LB Testing
resource "kubernetes_pod_v1" "curl_pod" {
  metadata {
    name = "curl-pod"
  }

  spec {
    container {
      image = "curlimages/curl"
      name  = "curl"
      command = [ "sleep", "600" ]
    }
  }
}