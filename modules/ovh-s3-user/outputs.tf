output "user_id" {
  description = "ID OpenStack du user créé"
  value       = ovh_cloud_project_user.this.id
}

output "username" {
  description = "Nom OpenStack du user (généré par OVH)"
  value       = ovh_cloud_project_user.this.username
}

output "access_key" {
  description = "Access Key S3"
  value       = ovh_cloud_project_user_s3_credential.this.access_key_id
  sensitive   = true
}

output "secret_key" {
  description = "Secret Key S3"
  value       = ovh_cloud_project_user_s3_credential.this.secret_access_key
  sensitive   = true
}
