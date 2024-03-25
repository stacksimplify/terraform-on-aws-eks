# Create S3 Bucket
resource "aws_s3_bucket" "mybucket" {
  bucket = "state-import-bucket"
  acl = "private"
  force_destroy = false
}

# terraform import aws_s3_bucket.mybucket state-import-bucket