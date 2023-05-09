# Resources: FluentBit 
## - ServiceAccount
## - ClusterRole
## - ClusterRoleBinding
## - ConfigMap: fluent-bit-config
## - DaemonSet

# Datasource
data "http" "get_fluentbit_resources" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

# Datasource: kubectl_file_documents 
# This provider provides a data resource kubectl_file_documents to enable ease of splitting multi-document yaml content.
data "kubectl_file_documents" "fluentbit_docs" {
    #content = data.http.get_fluentbit_resources.body
    content = data.http.get_fluentbit_resources.response_body
}

# Resource: kubectl_manifest which will create k8s Resources from the URL specified in above datasource
resource "kubectl_manifest" "fluentbit_resources" {
  depends_on = [
    kubernetes_namespace_v1.amazon_cloudwatch,
    kubernetes_config_map_v1.fluentbit_configmap,
    kubectl_manifest.cwagent_daemonset
    ]
  for_each = data.kubectl_file_documents.fluentbit_docs.manifests    
  yaml_body = each.value
}