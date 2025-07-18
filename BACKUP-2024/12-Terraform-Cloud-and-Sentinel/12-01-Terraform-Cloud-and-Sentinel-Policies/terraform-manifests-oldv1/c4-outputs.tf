# Output variable definitions

output "endpoint" {
  description = "Endpoint Information of the bucket"
  value       = aws_s3_bucket.s3_bucket.website_endpoint
}

output "bucket_website_endpoint_url" {
  value = "http://${aws_s3_bucket.s3_bucket.website_endpoint}/index.html"
}
