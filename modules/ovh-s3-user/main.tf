terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.0"
    }
  }
}

# Création d'un user OpenStack dans le projet cloud OVH
# Ce user est "OpenStack" au sens OVH, et peut générer des credentials S3
resource "ovh_cloud_project_user" "this" {
  service_name = var.service_name
  description  = var.user_description
  role_name    = var.user_role
}

# Génération des credentials S3 pour ce user
# Le couple (access_key, secret_key) est ce qu'on injecte ensuite dans Loki/Mimir/etc.
resource "ovh_cloud_project_user_s3_credential" "this" {
  service_name = var.service_name
  user_id      = ovh_cloud_project_user.this.id
}
