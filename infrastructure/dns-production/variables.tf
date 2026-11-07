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

# La cible de chaque zone. Au 7 novembre 2026, tout est sur infra01 (Hostinger,
# 72.62.185.244). jardinsvedas.com garde un AAAA historique (2001:41d0:301::29,
# un ancien hebergement OVH) qui ne designe PAS infra01 : a corriger a la
# bascule, pas avant, pour que l import donne un plan vide.
variable "targets" {
  type = map(object({ ipv4 = string, ipv6 = string }))
  default = {
    "leportail.org"       = { ipv4 = "72.62.185.244", ipv6 = "" }
    "fermedujointout.fr"  = { ipv4 = "72.62.185.244", ipv6 = "" }
    "jardinsvedas.com"    = { ipv4 = "72.62.185.244", ipv6 = "2001:41d0:301::29" }
    "labergeronnette.org" = { ipv4 = "72.62.185.244", ipv6 = "2a02:4780:28:9cbf::1" }
    "alter-it.eu"         = { ipv4 = "72.62.185.244", ipv6 = "2a02:4780:28:9cbf::1" }
  }
}

# Ou pointe « vault.<zone> ». Un seul coffre en production, chez infra01 ; apres
# la migration, chaque tenant a le sien : la valeur devient « <zone>. » par zone,
# et cette variable disparait.
variable "vault_target" {
  type    = string
  default = "infra01.alter-it.eu."
}
