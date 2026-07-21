# 1. Créer le user S3 dédié observability
module "s3_user_observability" {
  source = "../../modules/ovh-s3-user"
  
  service_name     = var.ovh_service_name
  user_description = "Tofu-managed observability user (Loki/Mimir/Tempo)"
}

# 2. Créer tous les buckets de la plateforme et des backups
module "buckets" {
  source = "../../modules/s3-buckets"
  
  buckets     = local.buckets
  common_tags = local.common_tags
}
