# ─────────────────────────────────────────────────────────────────────────────
# Secrets Talos
#
# Génère une fois les secrets cryptographiques du cluster (CA, certificats,
# tokens etcd/k8s). Racine de confiance. À garder dans un state distant CHIFFRÉ.
# ─────────────────────────────────────────────────────────────────────────────

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

locals {
  # Endpoint stable du cluster : le Load Balancer.
  cluster_endpoint = "https://${hcloud_load_balancer.control_plane.ipv4}:6443"
}

# ─────────────────────────────────────────────────────────────────────────────
# Configuration client (talosconfig)
# ─────────────────────────────────────────────────────────────────────────────

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = hcloud_server.node[*].ipv4_address
}

# ─────────────────────────────────────────────────────────────────────────────
# Config machine — appliquée à TOUS les nœuds (control-plane + workloads)
#
# Cette config est générée AVANT les serveurs et injectée dans leur user_data
# (voir servers.tf). Elle ne dépend que des secrets et de l'IP du LB, pas des
# serveurs eux-mêmes — d'où l'ordre LB → config → serveurs.
#
# allowSchedulingOnControlPlanes = true : les nœuds portent la charge applicative.
#
# Patches Hetzner :
#   - certSANs : l'IP du LB doit figurer dans les SANs du certificat API
#   - kubelet nodeIP : forcer l'IP du réseau privé (eth1)
#   - cni none : Cilium sera posé après le bootstrap
#
# externalCloudProvider / cloud-provider=external : suppose le déploiement de
# hcloud-cloud-controller-manager après le bootstrap. Pour un lab "ça démarre
# vite", retire ces 3 emplacements et les nœuds seront Ready sans CCM.
# ─────────────────────────────────────────────────────────────────────────────

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          extraMounts = [
            {
              destination = "/var/lib/longhorn",
              type = "bind",
              source = "/var/lib/longhorn",
              options = [
                "bind", 
                "rshared", 
                "rw"
              ]
            }
          ]
          nodeIP = {
            validSubnets = [var.node_subnet_cidr]
          }
        }
        # Sur hcloud, eth0 = public (DHCP), eth1 = réseau privé (DHCP aussi).
        network = {
          interfaces = [
            {
              interface = "eth0"
              dhcp      = true
            },
            {
              interface = "eth1"
              dhcp      = true
            }
          ]
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        network = {
          podSubnets     = [var.pod_cidr]
          serviceSubnets = [var.service_cidr]
          cni = {
            name = "none"
          }
        }
        # kube-proxy désactivé : Cilium le remplace entièrement en eBPF
        # (kube-proxy replacement). Talos ne déploiera pas le DaemonSet kube-proxy.
        proxy = {
          disabled = true
        }
        apiServer = {
          certSANs = [
            hcloud_load_balancer.control_plane.ipv4,
          ]
        }
        extraManifests = [
          var.cilium_manifest_url,
        ]
      }
    })
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Bootstrap — UNE SEULE FOIS, sur le premier nœud (initialise etcd)
#
# Les nœuds s'auto-configurent au boot via user_data ; il reste à amorcer etcd
# une seule fois. On cible l'IP publique du premier nœud (firewall ouvre 50000).
# depends_on sur les serveurs : ils doivent exister et avoir bootté.
# ─────────────────────────────────────────────────────────────────────────────

resource "talos_machine_bootstrap" "this" {
  node                 = hcloud_server.node[0].ipv4_address
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [
    hcloud_server.node,
    hcloud_server_network.node,
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Kubeconfig
# ─────────────────────────────────────────────────────────────────────────────

resource "talos_cluster_kubeconfig" "this" {
  node                 = hcloud_server.node[0].ipv4_address
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [talos_machine_bootstrap.this]
}