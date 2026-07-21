# OVH API credentials (pour gérer le user OpenStack)
variable "ovh_application_key" {
  type      = string
  sensitive = true
}

variable "ovh_application_secret" {
  type      = string
  sensitive = true
}

variable "ovh_consumer_key" {
  type      = string
  sensitive = true
}

variable "ovh_service_name" {
  description = "ID du projet cloud OVH (Public Cloud Project)"
  type        = string
}

variable "ovh_s3_region" {
  description = "Région S3 OVH"
  type        = string
  default     = "sbg"
}

# Credentials S3 OVH d'un user existant pour bootstrapper la création des buckets
# (le provider AWS a besoin de credentials valides pour créer les buckets)
variable "bootstrap_access_key" {
  type      = string
  sensitive = true
}

variable "bootstrap_secret_key" {
  type      = string
  sensitive = true
}
