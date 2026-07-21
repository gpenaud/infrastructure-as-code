# ─────────────────────────────────────────────────────────────────────────────
# Endpoint du control plane : Load Balancer Hetzner
#
# Endpoint stable, indépendant du cycle de vie des nœuds. Indispensable dès que
# node_count > 1 (plusieurs control-planes derrière une même IP).
#
# IMPORTANT : le LB doit exister AVANT les nœuds, car son IP est injectée dans
# la config Talos (certSANs + endpoint) qui part en user_data des serveurs.
# ─────────────────────────────────────────────────────────────────────────────

resource "hcloud_load_balancer" "control_plane" {
  name               = "${var.cluster_name}-cp-lb"
  load_balancer_type = "lb11"
  location           = var.location

  labels = {
    cluster = var.cluster_name
  }
}

resource "hcloud_load_balancer_network" "control_plane" {
  load_balancer_id = hcloud_load_balancer.control_plane.id
  subnet_id        = hcloud_network_subnet.nodes.id
}

# Le target sélectionne les nœuds par label : pas de dépendance Tofu explicite
# vers hcloud_server.node, donc pas de cycle (LB → config → serveurs → ce target).
resource "hcloud_load_balancer_target" "control_plane" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.control_plane.id
  label_selector   = "cluster=${var.cluster_name},role=controlplane"
  use_private_ip   = true
  depends_on       = [hcloud_load_balancer_network.control_plane]
}

resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.control_plane.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 80
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.control_plane.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443
}

resource "hcloud_load_balancer_service" "kube_api" {
  load_balancer_id = hcloud_load_balancer.control_plane.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "hcloud_load_balancer_service" "talos_api" {
  load_balancer_id = hcloud_load_balancer.control_plane.id
  protocol         = "tcp"
  listen_port      = 50000
  destination_port = 50000
}

# ─────────────────────────────────────────────────────────────────────────────
# Nœuds homogènes
#
# Tous identiques (node_type, 4 vCPU / 8 Go). Chaque nœud est un control-plane
# qui porte AUSSI les workloads — pas de workers dédiés.
#
# CLÉ DU FIX : sur la plateforme hcloud, Talos récupère sa config machine via le
# user-data du serveur (metadata 169.254.169.254). On la passe donc ici en
# user_data. Le nœud s'auto-configure au boot — PLUS BESOIN de
# talos_machine_configuration_apply (qui échouait car apid n'écoutait jamais,
# Talos restant bloqué à attendre ce user-data).
# ─────────────────────────────────────────────────────────────────────────────

resource "hcloud_server" "node" {
  count = var.node_count

  name        = "${var.cluster_name}-node-${count.index + 1}"
  server_type = var.node_type
  image       = data.hcloud_image.talos.id
  location    = var.location

  firewall_ids = [hcloud_firewall.this.id]

  # La config Talos complète est livrée au boot via le user-data.
  user_data = data.talos_machine_configuration.controlplane.machine_configuration

  labels = {
    cluster = var.cluster_name
    role    = "controlplane"
  }

  lifecycle {
    # Un re-push du snapshot (même version, nouvel ID) ne doit pas recréer le nœud.
    ignore_changes = [image]
  }
}

resource "hcloud_volume" "data" {
  count = var.node_count

  name     = "${var.cluster_name}-node-${count.index + 1}-data"
  size     = var.node_volume_size
  location = var.location

  labels = {
    role = "openebs-lvm"
    node = "${var.cluster_name}-node-${count.index + 1}"
  }

  delete_protection = false
}

resource "hcloud_volume_attachment" "data" {
  count = var.node_count

  volume_id = hcloud_volume.data[count.index].id
  server_id = hcloud_server.node[count.index].id
  automount = false
}

resource "hcloud_server_network" "node" {
  count     = var.node_count
  server_id = hcloud_server.node[count.index].id
  subnet_id = hcloud_network_subnet.nodes.id
}
