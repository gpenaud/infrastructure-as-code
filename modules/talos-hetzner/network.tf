# ─────────────────────────────────────────────────────────────────────────────
# Réseau privé Hetzner
#
# Les nœuds communiquent sur un réseau privé (etcd, API, kubelet) plutôt que par
# l'IP publique. Réduit la surface exposée et évite la facturation du trafic
# inter-nœuds.
# ─────────────────────────────────────────────────────────────────────────────

resource "hcloud_network" "this" {
  name     = "${var.cluster_name}-net"
  ip_range = var.private_network_cidr

  labels = {
    cluster = var.cluster_name
  }
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.node_subnet_cidr
}

# ─────────────────────────────────────────────────────────────────────────────
# Firewall
#
# Talos n'expose en propre que :
#   - 50000 : apid (talosctl)
# Plus 6443 pour l'API Kubernetes.
# Le reste (etcd, kubelet, trustd, CNI) passe par le réseau privé, non exposé.
# ─────────────────────────────────────────────────────────────────────────────

resource "hcloud_firewall" "this" {
  name = "${var.cluster_name}-fw"

  labels = {
    cluster = var.cluster_name
  }

  rule {
    description = "Talos API (talosctl)"
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Kubernetes API"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "TCP 80 (forward traffic)"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "TCP 443 (forward traffic)"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
