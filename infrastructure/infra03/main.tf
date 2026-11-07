# ─────────────────────────────────────────────────────────────────────────────
# infra03 — un VPS unique chez Hetzner, en docker-compose.
#
# Pas de cluster ici, contrairement à infra02 : une machine, Ubuntu, Docker, et
# trois instances de tenant-infra derrière un gateway. Cette racine crée ce qui
# vit HORS de la machine et doit lui survivre :
#
#   server.tf   le serveur, sa clé SSH, son pare-feu Hetzner
#   dns.tf      les noms de staging dans la zone OVH alter-it.eu
#   (le bucket des sauvegardes restic est dans infrastructure/backups depuis le 7 novembre 2026)
#
# Ce qui vit DANS la machine (durcissement, Docker, les piles) est joué par
# Ansible : ~/work/ansible/playbooks/deploy-vps.yml.
#
# LE PROJET HETZNER N EST PAS CELUI D INFRA02. Le workflow
# .github/workflows/infra02-nightly-nuke.yaml vide chaque soir le projet
# 14748868 (nuke-config.yaml) et échoue s il y reste un serveur. Un VPS de
# production créé là-dedans ne passerait pas la nuit. Le jeton de cette racine
# doit venir d un projet Hetzner distinct, réservé à la production.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.7"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    # Zone DNS et compte S3 (voir dns.tf, s3.tf).
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.0"
    }
  }

  # Le bucket de state est déclaré dans infrastructure/s3-buckets, pas ici :
  # une racine ne peut pas gérer le bucket qui porte son propre state.
  #
  #   tofu init -backend-config="access_key=…" -backend-config="secret_key=…"
  backend "s3" {
    bucket                      = "alter-it-infra03-tofu-state"
    key                         = "terraform.tfstate"
    region                      = "sbg"
    endpoints                   = { s3 = "https://s3.sbg.io.cloud.ovh.net" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Deux clés OVH, parce que deux périmètres : celle-ci porte /cloud/* (le compte
# S3), l autre /domain/zone/* (le DNS). Une seule clé qui porterait les deux
# serait plus simple, mais celles qui existent ne se recoupent pas.
provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

provider "ovh" {
  alias              = "dns"
  endpoint           = "ovh-eu"
  application_key    = var.ovh_dns_application_key
  application_secret = var.ovh_dns_application_secret
  consumer_key       = var.ovh_dns_consumer_key
}


locals {
  name  = "infra03"
  owner = "alter-it"

  common_labels = {
    managed-by = "opentofu"
    root       = "infrastructure-infra03"
    owner      = local.owner
    env        = "production"
  }
}
