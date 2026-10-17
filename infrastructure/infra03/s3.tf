# ─────────────────────────────────────────────────────────────────────────────
# Les sauvegardes : un bucket, et PAS de compte dédié.
#
# Chez OVH, un bucket appartient à l utilisateur S3 qui l a créé, et les
# politiques de bucket (GetBucketPolicy) répondent « Not implemented » sur cet
# endpoint : impossible de donner à un second utilisateur l accès aux dépôts
# d infra01, ni même à ce bucket-ci. Vérifié le 2026-10-17 : un compte créé ici
# (user-33cy7GU6yacj) ne voyait rien, refus sur chaque bucket.
#
# L utilisateur qui possède tout — alter-it-infra01-backup-* ET alter-it-backups
# — est celui des identifiants k8up du cluster (user-pT6nuZtRK4uu), les mêmes
# que les clés « bootstrap » de infrastructure/s3-buckets. Ce sont donc eux
# qui vont dans le .env.restore de chaque instance : lecture d infra01 pour
# restaurer, écriture d infra03 pour sauvegarder. Un seul secret de plus à
# faire tourner le jour où il tourne.
# ─────────────────────────────────────────────────────────────────────────────

module "backup_bucket" {
  source = "../../modules/s3-buckets"
  count  = var.manage_s3 ? 1 : 0

  buckets = {
    backups = {
      name            = var.backup_bucket
      expiration_days = 0
    }
  }

  # Il contient les sauvegardes de tous les tenants : un destroy doit échouer.
  prevent_destroy = true

  common_tags = {
    ManagedBy   = "OpenTofu"
    Repo        = "infrastructure-as-code"
    Root        = "infrastructure/infra03"
    Server      = local.name
    Owner       = local.owner
    Environment = "production"
  }
}
