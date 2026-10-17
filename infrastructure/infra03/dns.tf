# ─────────────────────────────────────────────────────────────────────────────
# Les noms de staging, dans la zone de CHAQUE tenant.
#
# Le schéma était déjà en place chez OVH, posé pour infra02 : « *.staging » en
# CNAME vers « staging.<zone> », et un seul « staging » à faire pointer. Il est
# repris tel quel ; les enregistrements qui existaient (les trois CNAME, le A de
# jardinsvedas.com) ont été IMPORTÉS dans ce state, pas recréés — voir README.
#
# external-dns sur infra01 écrit aussi dans ces zones, en « upsert-only » : il
# ne supprime rien, et ne toucherait « staging.<zone> » que si un Ingress du
# cluster portait encore ce nom.
#
# « infra03.alter-it.eu » est le nom de la machine elle-même : SSH, Ansible.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  dns_targets = {
    A    = hcloud_server.this.ipv4_address
    AAAA = hcloud_server.this.ipv6_address
  }

  dns_records = var.manage_dns ? merge(
    { for t in ["A", "AAAA"] :
      "host-${t}" => { zone = var.dns_zone, subdomain = local.name, type = t, target = local.dns_targets[t] }
    },
    # Les services de la MACHINE, qui n appartiennent a aucun tenant :
    # grafana.infra03, et ce qui viendra. Un joker, pour ne pas revenir ici a
    # chaque nom.
    { for t in ["A", "AAAA"] :
      "host-wildcard-${t}" => { zone = var.dns_zone, subdomain = "*.${local.name}", type = t, target = local.dns_targets[t] }
    },
    { for tenant, zone in var.tenants :
      "${tenant}-cname" => { zone = zone, subdomain = "*.staging", type = "CNAME", target = "staging.${zone}." }
    },
    { for pair in setproduct(keys(var.tenants), ["A", "AAAA"]) :
      "${pair[0]}-${pair[1]}" => { zone = var.tenants[pair[0]], subdomain = "staging", type = pair[1], target = local.dns_targets[pair[1]] }
    }
  ) : {}
}

resource "ovh_domain_zone_record" "this" {
  for_each = local.dns_records
  provider = ovh.dns

  zone      = each.value.zone
  subdomain = each.value.subdomain
  fieldtype = each.value.type
  ttl       = 300
  target    = each.value.target
}
