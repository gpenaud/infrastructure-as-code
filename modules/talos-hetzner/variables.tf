variable "hcloud_token" {
  description = "Token API Hetzner Cloud (scope read/write)."
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Nom logique du cluster, utilisé en préfixe des ressources."
  type        = string
  default     = "talos-lab"
}

variable "talos_version" {
  description = "Version de Talos. Doit correspondre au snapshot poussé via hcloud-upload-image."
  type        = string
  default     = "v1.9.5"
}

variable "kubernetes_version" {
  description = "Version de Kubernetes embarquée par Talos."
  type        = string
  default     = "v1.32.0"
}

variable "location" {
  description = "Datacenter Hetzner (fsn1, nbg1, hel1, ...)."
  type        = string
  default     = "fsn1"
}

variable "network_zone" {
  description = "Zone réseau Hetzner correspondant à la location (eu-central pour fsn1/nbg1/hel1)."
  type        = string
  default     = "eu-central"
}

# ─────────────────────────────────────────────────────────────────────────────
# Nœuds homogènes : un seul type, un seul count.
# Chaque nœud est un control-plane qui porte AUSSI les workloads.
# cx42 = 4 vCPU / 8 Go (Intel partagé). cpx41 = équivalent AMD, un peu plus rapide.
# ─────────────────────────────────────────────────────────────────────────────

variable "node_type" {
  description = "Type de serveur Hetzner pour tous les nœuds (4 vCPU / 8 Go)."
  type        = string
  default     = "cx33"
}

variable "node_count" {
  description = "Nombre de nœuds. 1 pour un lab jetable, 3 pour un quorum etcd HA."
  type        = number
  default     = 3

  validation {
    condition     = contains([1, 3, 5], var.node_count)
    error_message = "Le nombre de nœuds doit être 1, 3 ou 5 (quorum etcd impair)."
  }
}

variable "node_volume_size" {
  description = "Taille du volume pour tous les nœuds (en Go)."
  type        = number
  default     = 70
}

variable "pod_cidr" {
  description = "CIDR des pods (réseau interne Kubernetes)."
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR des services Kubernetes."
  type        = string
  default     = "10.96.0.0/12"
}

variable "private_network_cidr" {
  description = "CIDR du réseau privé Hetzner reliant les nœuds."
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_subnet_cidr" {
  description = "Sous-réseau Hetzner dans lequel les nœuds reçoivent leur IP privée."
  type        = string
  default     = "10.0.1.0/24"
}

variable "cilium_manifest_url" {
  description = <<-EOT
    URL publique du manifeste Cilium rendu (helm template). Talos la fetch au
    bootstrap du control plane via extraManifests et l'applique → le cluster
    naît avec son CNI. Doit être accessible sans authentification (Talos
    n'envoie pas de credentials). Ex S3 OVH public-read :
    https://mon-bucket.s3.sbg.io.cloud.ovh.net/talos/cilium.yaml
  EOT
  type        = string
}