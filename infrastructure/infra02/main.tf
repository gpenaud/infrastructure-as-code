# ─────────────────────────────────────────────────────────────────────────────
# Racine : configure les providers et appelle le module talos-hetzner.
#
# Le module crée le réseau privé, les nœuds homogènes (control-plane + workloads),
# le load balancer, et bootstrappe Talos. On lui passe nos valeurs ; les defaults
# du module couvrent le reste.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.7"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # Backend distant CHIFFRÉ recommandé : le state contient les secrets Talos
  # (CA, clés etcd/k8s). Exemple S3-compatible (adapte à ton OVH/Hetzner/MinIO) :
  
  backend "s3" {
    bucket                      = "alter-it-infra02-tofu-state"
    key                         = "terraform.tfstate"
    region                      = "sbg"
    endpoints                   = { s3 = "https://s3.sbg.io.cloud.ovh.net" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

variable "hcloud_token" {
  description = "Token API Hetzner Cloud (scope read/write)."
  type        = string
  sensitive   = true
}

variable "server_type" {
  type    = string
  default = "cx33"
}

variable "server_count" {
  type    = number
  default = 1
}

variable "preferred_locations" {
  description = "Locations par ordre de préférence, toutes zones confondues"
  type        = list(string)
  default     = ["nbg1", "fsn1", "hel1", "ash", "hil", "sin"]
}

provider "hcloud" {
  token = var.hcloud_token
}

# Le provider talos n'a pas de configuration globale : tout passe par les
# ressources (secrets, configs) générées dans le module.
provider "talos" {}

data "hcloud_server_type" "wanted" {
  name = var.server_type
}

locals {
  # Locations où le type est réellement commandable
  available_locations = [
    for loc in data.hcloud_server_type.wanted.locations :
    loc.name
    if loc.available
  ]

  candidate_locations = [
    for loc in var.preferred_locations : loc
    if contains(local.available_locations, loc)
  ]
}

resource "terraform_data" "availability_check" {
  lifecycle {
    precondition {
      condition     = length(local.candidate_locations) > 0
      error_message = "Aucune location préférée ne propose ${var.server_type}. Disponible dans : ${join(", ", local.available_locations)}"
    }
  }
}

resource "terraform_data" "pinned_location" {
  input = local.candidate_locations[0]

  lifecycle {
    ignore_changes = [input]

    precondition {
      condition     = length(local.candidate_locations) > 0
      error_message = <<-EOT
        Aucune location préférée ne propose ${var.server_type}.
        Locations avec disponibilité : ${length(local.available_locations) > 0 ? join(", ", local.available_locations) : "aucune"}
        Locations proposant ce type (dispo ou non) : ${join(", ", [for l in data.hcloud_server_type.wanted.locations : l.name])}
      EOT
    }
  }
}

module "cluster" {
  source = "./../../modules/talos-hetzner"

  hcloud_token = var.hcloud_token

  cluster_name       = "infra02"
  talos_version      = "v1.9.5"
  kubernetes_version = "v1.33.0"

  ###
  # Possible zones & locations Hetzner (2024-06):
  #
  # eu-central: nbg1, fsn1, hel1
  # us-east: ash
  # eu-west: hil 
  # ap-southeast: sin
  ###
  location     = terraform_data.pinned_location.output
  network_zone = "eu-central"

  # Nœuds homogènes : 3 × cx33 (4 vCPU / 8 Go), chacun control-plane + workloads.
  node_type  = var.server_type
  node_count = var.server_count
  node_volume_size = 200 # 70 Go by default 

  cilium_manifest_url = "https://alter-it-bootstrap-resources.s3.sbg.io.cloud.ovh.net/talos/cilium.yaml"
}

# ─────────────────────────────────────────────────────────────────────────────
# On ré-expose les outputs du module au niveau racine pour pouvoir faire
# `tofu output -raw kubeconfig`, etc.
# ─────────────────────────────────────────────────────────────────────────────

output "talosconfig" {
  value     = module.cluster.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.cluster.kubeconfig
  sensitive = true
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "node_ips" {
  value = module.cluster.node_ips
}
