# ─────────────────────────────────────────────────────────────────────────────
# dns-production — les enregistrements DNS de PRODUCTION des tenants et
# d alter-it.eu, dans les zones OVH.
#
# Ils etaient ecrits par external-dns depuis infra01 (politique upsert-only,
# registre TXT). Cette racine les reprend, IMPORTES et non recrees, pour que la
# bascule d une zone soit un changement de variable et un « tofu apply », et
# non une suite de gestes a la console.
#
# La forme de chaque zone est la meme : un A (et un AAAA) sur l apex, et « * »
# en CNAME vers l apex ; chaque application est un nom sous la zone, donc suit
# l apex. Deux exceptions, « vault » chez le-portail et ferme-du-jointout,
# en CNAME vers infra01.alter-it.eu : le coffre etait commun.
#
# Ce que cette racine NE gere PAS : le courrier (MX, SPF, DKIM, DMARC, autoconfig),
# les noms de staging (racine infra03), les CNAME applicatifs vers l apex, les
# TXT de propriete d external-dns. L export complet des zones est dans
# migration-k8s-compose/dns/.
#
# Migration (migration-k8s-compose, SPEC § DNS) : external-dns doit etre
# SUSPENDU avant tout apply qui change un apex, sinon il le reecrit.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.7"
  required_providers {
    ovh = { source = "ovh/ovh", version = "~> 2.0" }
  }
  # Le state dans le bucket « platform », comme s3-buckets : un etat par racine.
  #   tofu init -backend-config="access_key=…" -backend-config="secret_key=…"
  backend "s3" {
    bucket                      = "alter-it-infra01-platform-tofu-state"
    key                         = "dns-production/terraform.tfstate"
    region                      = "sbg"
    endpoints                   = { s3 = "https://s3.sbg.io.cloud.ovh.net" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_dns_application_key
  application_secret = var.ovh_dns_application_secret
  consumer_key       = var.ovh_dns_consumer_key
}

locals {
  # La machine qui sert la production, zone par zone. Chaque zone peut
  # basculer seule : c est ce que la migration fait, les quatre a la suite.
  zones = {
    "leportail.org"       = { ipv4 = var.targets["leportail.org"].ipv4, ipv6 = var.targets["leportail.org"].ipv6 }
    "fermedujointout.fr"  = { ipv4 = var.targets["fermedujointout.fr"].ipv4, ipv6 = var.targets["fermedujointout.fr"].ipv6 }
    "jardinsvedas.com"    = { ipv4 = var.targets["jardinsvedas.com"].ipv4, ipv6 = var.targets["jardinsvedas.com"].ipv6 }
    "labergeronnette.org" = { ipv4 = var.targets["labergeronnette.org"].ipv4, ipv6 = var.targets["labergeronnette.org"].ipv6 }
    "alter-it.eu"         = { ipv4 = var.targets["alter-it.eu"].ipv4, ipv6 = var.targets["alter-it.eu"].ipv6 }
  }

  # Un enregistrement par cle ; la cle est aussi celle de l import.
  # Les TTL sont ceux trouves le 7 novembre 2026 (0 = defaut de la zone) : les
  # changer est un vrai changement, a faire exprès.
  records = merge(
    # apex A, partout
    { for z, t in local.zones : "${z}/apex-A" => { zone = z, sub = "", type = "A", ttl = 0, target = t.ipv4 } },
    # apex AAAA, la ou il existe (pas chez le-portail ni ferme-du-jointout)
    { for z in ["jardinsvedas.com", "labergeronnette.org", "alter-it.eu"] :
    "${z}/apex-AAAA" => { zone = z, sub = "", type = "AAAA", ttl = 0, target = local.zones[z].ipv6 } },
    # « * » vers l apex
    { for z, ttl in { "leportail.org" = 60, "fermedujointout.fr" = 60, "jardinsvedas.com" = 0, "labergeronnette.org" = 60, "alter-it.eu" = 60 } :
    "${z}/star-CNAME" => { zone = z, sub = "*", type = "CNAME", ttl = ttl, target = "${z}." } },
    # « www » la ou il existe explicitement
    { for z, ttl in { "leportail.org" = 60, "labergeronnette.org" = 0 } :
    "${z}/www-CNAME" => { zone = z, sub = "www", type = "CNAME", ttl = ttl, target = "${z}." } },
    # le coffre : commun en production, un par tenant apres la migration
    { for z in ["leportail.org", "fermedujointout.fr", "alter-it.eu"] :
    "${z}/vault-CNAME" => { zone = z, sub = "vault", type = "CNAME", ttl = 300, target = var.vault_target } },
    # le nom de la machine de production elle-meme
    {
      "alter-it.eu/infra01-A"    = { zone = "alter-it.eu", sub = "infra01", type = "A", ttl = 0, target = var.targets["alter-it.eu"].ipv4 }
      "alter-it.eu/infra01-AAAA" = { zone = "alter-it.eu", sub = "infra01", type = "AAAA", ttl = 0, target = var.targets["alter-it.eu"].ipv6 }
    },
  )
}

resource "ovh_domain_zone_record" "this" {
  for_each  = local.records
  zone      = each.value.zone
  subdomain = each.value.sub
  fieldtype = each.value.type
  ttl       = each.value.ttl
  target    = each.value.target
}

output "records" {
  value = { for k, r in ovh_domain_zone_record.this : k => "${r.fieldtype} ${r.subdomain == "" ? "@" : r.subdomain}.${r.zone} -> ${r.target}" }
}
