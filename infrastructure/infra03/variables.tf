# --- Jetons et clés ----------------------------------------------------------

variable "hcloud_token" {
  description = "Jeton API Hetzner Cloud (lecture/écriture) du projet de PRODUCTION, pas celui du lab."
  type        = string
  sensitive   = true
}

variable "ovh_application_key" {
  type      = string
  sensitive = true
}

variable "ovh_application_secret" {
  type      = string
  sensitive = true
}

variable "ovh_consumer_key" {
  description = "Clé « cloud » : /cloud/project/* (compte S3). Celle de infrastructure/s3-buckets."
  type        = string
  sensitive   = true
}

variable "ovh_dns_application_key" {
  type      = string
  sensitive = true
}

variable "ovh_dns_application_secret" {
  type      = string
  sensitive = true
}

variable "ovh_dns_consumer_key" {
  description = "Clé « dns » : GET/POST/PUT/DELETE sur /domain/zone/*/record*, POST /domain/zone/*/refresh."
  type        = string
  sensitive   = true
}

variable "ovh_service_name" {
  description = "ID du projet Public Cloud OVH, où vivent les buckets."
  type        = string
}




# --- Le serveur ---------------------------------------------------------------

variable "server_type" {
  description = "CX43 : 8 vCPU partagés, 16 Go, 160 Go. Trois tenants, une vingtaine de conteneurs."
  type        = string
  default     = "cx43"
}

variable "location" {
  description = "fsn1 (Falkenstein). nbg1 et hel1 sont les autres sites européens."
  type        = string
  default     = "fsn1"
}

variable "image" {
  description = "Le rôle gpenaud.secured-server vise Ubuntu : il supprime l utilisateur « ubuntu » et active les dépôts Ubuntu de crowdsec."
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_public_key_path" {
  description = "La clé que le rôle secured-server autorise aussi pour « operator » : la même, pour ne pas en gérer deux."
  type        = string
  default     = "~/.ssh/work.pub"
}

variable "hetzner_backups" {
  description = <<-EOT
    Instantanés quotidiens du disque entier par Hetzner, sept conservés, +20 % du
    prix du serveur. Ce n est PAS la sauvegarde des données — restic s en charge,
    par application, vers S3 — mais le moyen de ravoir la machine entière en
    quelques minutes après une fausse manœuvre.
  EOT
  type        = bool
  default     = true
}

# --- DNS -----------------------------------------------------------------------

variable "manage_dns" {
  description = "Écrire les noms de staging dans la zone OVH. false si la clé OVH n a pas les droits /domain."
  type        = bool
  default     = true
}

variable "dns_zone" {
  type    = string
  default = "alter-it.eu"
}

variable "tenants" {
  description = <<-EOT
    Les tenants servis, et la ZONE DNS de chacun. Le staging d un tenant vit
    dans sa propre zone : BASE_DOMAIN = « staging.<zone> », et les applications
    sous « auth.staging.<zone> », « www.staging.<zone> », etc. Un joker
    « *.staging » en CNAME vers « staging.<zone> » existait déjà dans chaque
    zone ; Tofu le reprend et fait pointer « staging » sur ce serveur.

    Les noms de PRODUCTION (auth.<zone>, www.<zone>) restent sur infra01 jusqu à
    la bascule, zone par zone.
  EOT
  type        = map(string)
  default = {
    "le-portail"        = "leportail.org"
    "ferme-du-jointout" = "fermedujointout.fr"
    "jardins-vedas"     = "jardinsvedas.com"
    # Ajoute le 7 novembre 2026 pour la migration d infra01 : le joker *.staging existait deja, importe.
    "la-bergeronnette" = "labergeronnette.org"
  }
}

# --- Sauvegardes : le bucket alter-it-backups vit dans infrastructure/backups depuis le 7 novembre 2026 ---


