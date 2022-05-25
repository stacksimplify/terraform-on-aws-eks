# Helm Release Outputs
output "metrics_server_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value = helm_release.metrics_server_release.metadata
}
