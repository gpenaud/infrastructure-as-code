# Backend distant, tel que .terraform/terraform.tfstate le connaissait déjà :
# le state de cette racine vit dans le bucket de plateforme d'infra01. Le bloc
# n'était pas versionné, ce qui obligeait à le retrouver à chaque poste.
#
#   tofu init -backend-config="access_key=…" -backend-config="secret_key=…"
#
# (les clés « bootstrap_* » de terraform.tfvars)
terraform {
  backend "s3" {
    bucket                      = "alter-it-infra01-platform-tofu-state"
    key                         = "platform-buckets/terraform.tfstate"
    region                      = "sbg"
    endpoints                   = { s3 = "https://s3.sbg.io.cloud.ovh.net" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
