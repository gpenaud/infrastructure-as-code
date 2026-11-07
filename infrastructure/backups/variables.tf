variable "ovh_s3_region" {
  type    = string
  default = "sbg"
}
variable "s3_access_key" {
  type      = string
  sensitive = true
}
variable "s3_secret_key" {
  type      = string
  sensitive = true
}
variable "backup_bucket" {
  type    = string
  default = "alter-it-backups"
}
