locals {
  common_tags = {
    ManagedBy   = "OpenTofu"
    Repo        = "alter-it-obs-infra"
    Environment = "production"
    Project     = "infra01"
    Owner       = "alter-it"
  }
  
  # Liste des buckets à créer
  # expiration_days = 0 → pas d'expiration
  # expiration_days = N → objets supprimés après N jours
  buckets = {
    # Plateforme du serveur infra01
    "loki-rules" = {
      name            = "alter-it-infra01-platform-loki-rules"
      expiration_days = 0  # rules = à garder, jamais expirer
    }
    "loki-chunks" = {
      name            = "alter-it-infra01-platform-loki-chunks"
      expiration_days = 30  # 30j de logs, au-delà supprimés
    }
    "mimir-blocks" = {
      name            = "alter-it-infra01-platform-mimir-blocks"
      expiration_days = 90  # 90j de métriques long-term
    }
    "mimir-rules" = {
      name            = "alter-it-infra01-platform-mimir-rules"
      expiration_days = 0
    }
    "tempo-traces" = {
      name            = "alter-it-infra01-platform-tempo-traces"
      expiration_days = 14  # 14j de traces
    }

    # Plateforme du serveur infra02
    "infra02-loki-rules" = {
      name            = "alter-it-infra02-platform-loki-rules"
      expiration_days = 0  # rules = à garder, jamais expirer
    }
    "infra02-loki-chunks" = {
      name            = "alter-it-infra02-platform-loki-chunks"
      expiration_days = 30  # 30j de logs, au-delà supprimés
    }
    "infra02-mimir-blocks" = {
      name            = "alter-it-infra02-platform-mimir-blocks"
      expiration_days = 90  # 90j de métriques long-term
    }
    "infra02-mimir-rules" = {
      name            = "alter-it-infra02-platform-mimir-rules"
      expiration_days = 0
    }
    "infra02-tempo-traces" = {
      name            = "alter-it-infra02-platform-tempo-traces"
      expiration_days = 14  # 14j de traces
    }

    # Resources de bootstrap
    "bootstrap-cilium-resources" = {
      name            = "alter-it-bootstrap-resources"
      expiration_days = 0
    }

    # Plateforme du serveur infra02
    "infra02-tofu-state" = {
      name            = "alter-it-infra02-tofu-state"
      expiration_days = 0
    }

    # Backups par tenant × service
    "backup-fdj-nextcloud" = {
      name            = "alter-it-infra01-backup-ferme-du-jointout-nextcloud"
      expiration_days = 0  # k8up gère sa propre rétention via prune
    }
    "backup-fdj-dolibarr" = {
      name            = "alter-it-infra01-backup-ferme-du-jointout-dolibarr"
      expiration_days = 0
    }
    "backup-fdj-wordpress" = {
      name            = "alter-it-infra01-backup-ferme-du-jointout-wordpress-site"
      expiration_days = 0
    }
    "backup-lp-alterconso" = {
      name            = "alter-it-infra01-backup-le-portail-alterconso"
      expiration_days = 0
    }
    "backup-lp-dolibarr" = {
      name            = "alter-it-infra01-backup-le-portail-dolibarr"
      expiration_days = 0
    }
    "backup-lp-grist" = {
      name            = "alter-it-infra01-backup-le-portail-grist"
      expiration_days = 0
    }
    "backup-lp-wordpress-epilibres" = {
      name            = "alter-it-infra01-backup-le-portail-wordpress-epilibres"
      expiration_days = 0
    }
    "backup-lp-wordpress-site" = {
      name            = "alter-it-infra01-backup-le-portail-wordpress-site"
      expiration_days = 0
    }
    "backup-lb-wordpress" = {
      name            = "alter-it-infra01-backup-la-bergeronnette-wordpress-site"
      expiration_days = 0
    }
  }
}
