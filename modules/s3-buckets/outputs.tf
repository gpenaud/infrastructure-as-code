output "bucket_names" {
  description = "Map nom logique → nom réel du bucket"
  value = {
    for k, v in aws_s3_bucket.this : k => v.id
  }
}

output "bucket_arns" {
  description = "Map nom logique → ARN du bucket (utile pour les bucket policies)"
  value = {
    for k, v in aws_s3_bucket.this : k => v.arn
  }
}
