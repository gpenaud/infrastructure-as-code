# Provider OVH : pour gérer le user OpenStack et ses credentials S3
provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

# Provider AWS : pointé sur l'endpoint OVH S3 pour gérer les buckets
provider "aws" {
  region = var.ovh_s3_region
  
  endpoints {
    s3 = "https://s3.${var.ovh_s3_region}.io.cloud.ovh.net"
  }
  
  # Credentials d'un user existant qui peut créer des buckets
  # (typiquement les mêmes que tu utilises pour aws-cli aujourd'hui)
  access_key = var.bootstrap_access_key
  secret_key = var.bootstrap_secret_key
  
  # Désactivation des comportements AWS-only qui cassent sur OVH
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  
  # OVH attend des bucket names en path-style, pas virtual-hosted-style
  s3_use_path_style = true
}
