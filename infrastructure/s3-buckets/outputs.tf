output "observability_user_access_key" {
  description = "Access Key du user observability (à injecter dans SOPS Flux)"
  value       = module.s3_user_observability.access_key
  sensitive   = true
}

output "observability_user_secret_key" {
  description = "Secret Key du user observability"
  value       = module.s3_user_observability.secret_key
  sensitive   = true
}

output "bucket_names" {
  description = "Liste de tous les buckets créés (nom logique → nom S3 réel)"
  value       = module.buckets.bucket_names
}
