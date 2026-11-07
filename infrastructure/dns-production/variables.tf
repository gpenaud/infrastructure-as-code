variable "ovh_dns_application_key" {
  type      = string
  sensitive = true
}
variable "ovh_dns_application_secret" {
  type      = string
  sensitive = true
}
variable "ovh_dns_consumer_key" {
  type      = string
  sensitive = true
}

# La cible de chaque zone.
variable "targets" {
  type = map(object({ ipv4 = string, ipv6 = string }))
  # ETAT REEL : les quatre zones de tenants servies par infra03 (Hetzner) depuis
  # la bascule du 7 novembre 2026 au soir ; alter-it.eu reste sur infra01
  # (Hostinger). Les defauts DOIVENT refleter l etat en place : un apply nu
  # avec des defauts perimes ramenerait la production en arriere.
  default = {
    "leportail.org"       = { ipv4 = "2.28.130.9", ipv6 = "" }
    "fermedujointout.fr"  = { ipv4 = "2.28.130.9", ipv6 = "" }
    "jardinsvedas.com"    = { ipv4 = "2.28.130.9", ipv6 = "2a01:4f8:c012:9728::1" }
    "labergeronnette.org" = { ipv4 = "2.28.130.9", ipv6 = "2a01:4f8:c012:9728::1" }
    "alter-it.eu"         = { ipv4 = "72.62.185.244", ipv6 = "2a02:4780:28:9cbf::1" }
  }
}

# Ou pointe « vault.<zone> ». Un seul coffre en production, chez infra01 ; apres
# la migration, chaque tenant a le sien : la valeur devient « <zone>. » par zone,
# et cette variable disparait.
variable "vault_target" {
  type = map(string)
  default = {
    "leportail.org"      = "infra01.alter-it.eu."
    "fermedujointout.fr" = "infra01.alter-it.eu."
    "alter-it.eu"        = "infra01.alter-it.eu."
  }
}

# TTL des enregistrements d apex, par zone. 0 = le defaut de la zone OVH
# (3600 s). A 300 pendant la migration : un apex qui change se propage en
# cinq minutes. alter-it.eu ne bouge pas ce soir et garde son defaut.
variable "apex_ttl" {
  type = map(number)
  default = {
    "leportail.org"       = 300
    "fermedujointout.fr"  = 300
    "jardinsvedas.com"    = 300
    "labergeronnette.org" = 300
    "alter-it.eu"         = 0
  }
}

# Ou pointe vault.infra01.alter-it.eu, l adresse du coffre que connaissent les
# clients Bitwarden. infra01.alter-it.eu. tant que le coffre y tourne ;
# leportail.org. une fois repris par le tenant le-portail sur la machine qui
# sert leportail.org.
variable "vault_infra01_target" {
  type = string
  # leportail.org. depuis le 7 novembre 2026 au soir : le coffre commun est
  # repris par le tenant le-portail sur la machine qui sert leportail.org.
  default = "leportail.org."
}
