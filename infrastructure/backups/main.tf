# ─────────────────────────────────────────────────────────────────────────────
# backups — le bucket des sauvegardes restic de tous les tenants.
#
# Il vivait dans la racine infra03, la machine qui l a vu naitre. Deplace ici
# le 7 novembre 2026 (tofu state mv, sans toucher au bucket) parce qu il doit
# SURVIVRE a infra03 : la migration detruit cette machine, et les sauvegardes
# restent. Une racine qui ne porte que ce qui dure.
#
# Le bucket appartient a l utilisateur S3 des identifiants k8up
# (user-pT6nuZtRK4uu), le seul chez OVH qui voie aussi les depots d infra01 :
# voir le commentaire historique dans infra03/s3.tf avant son retrait.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket                      = "alter-it-infra01-platform-tofu-state"
    key                         = "backups/terraform.tfstate"
    region                      = "sbg"
    endpoints                   = { s3 = "https://s3.sbg.io.cloud.ovh.net" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

provider "aws" {
  region = var.ovh_s3_region
  endpoints { s3 = "https://s3.${var.ovh_s3_region}.io.cloud.ovh.net" }
  access_key                  = var.s3_access_key
  secret_key                  = var.s3_secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
}

module "backup_bucket" {
  source = "../../modules/s3-buckets"
  buckets = {
    backups = {
      name            = var.backup_bucket
      expiration_days = 0
    }
  }
  # Il contient les sauvegardes de tous les tenants : un destroy doit echouer.
  prevent_destroy = true
  # Les etiquettes de la racine d origine, gardees telles quelles pour que le
  # deplacement d etat donne un plan vide ; a rafraichir un jour, expres.
  common_tags = {
    ManagedBy   = "OpenTofu"
    Repo        = "infrastructure-as-code"
    Root        = "infrastructure/infra03"
    Server      = "infra03"
    Owner       = "alter-it"
    Environment = "production"
  }
}

output "backup_bucket" { value = var.backup_bucket }
