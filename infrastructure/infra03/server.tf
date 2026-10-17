# ─────────────────────────────────────────────────────────────────────────────
# Le serveur.
#
# Un seul disque, celui du serveur (160 Go) : les volumes Docker et les
# instances y vivent. Un volume Hetzner séparé aurait permis de rattacher les
# données à une machine neuve, mais Docker les range sous /var/lib/docker et
# les déplacer sur un volume ajoute une couche à comprendre pour qui reprend la
# machine. Les instantanés Hetzner couvrent le cas « ravoir la machine », restic
# le cas « ravoir les données ».
# ─────────────────────────────────────────────────────────────────────────────

resource "hcloud_ssh_key" "operator" {
  name       = "${local.name}-operator"
  public_key = file(pathexpand(var.ssh_public_key_path))
  labels     = local.common_labels
}

# PAS DE PARE-FEU HETZNER, et c est voulu : la cible finale de ces tenants est
# un VPS Hostinger, où il n existerait pas. Tout ce qui filtre vit DANS la
# machine — ufw et la chaîne DOCKER-USER posées par Ansible — et suit donc le
# déplacement. Un filtre propre à l hébergeur aurait donné une protection que
# la migration aurait perdue sans rien dire.

resource "hcloud_server" "this" {
  name        = local.name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.operator.id]
  backups     = var.hetzner_backups
  labels      = local.common_labels

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  # Hetzner pose la clé SSH sur root : c est par là qu Ansible entre la
  # première fois. Le rôle secured-server crée ensuite « operator », et ferme
  # SSH à tout autre compte.

  lifecycle {
    # Changer d image ou de type recrée ou redimensionne la machine : jamais
    # par un apply distrait.
    prevent_destroy = true
    ignore_changes  = [ssh_keys]
  }
}
