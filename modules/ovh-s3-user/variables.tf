variable "service_name" {
  description = "ID du projet cloud OVH (Public Cloud Project ID)"
  type        = string
}

variable "user_description" {
  description = "Description du user OpenStack (visible dans la console OVH)"
  type        = string
  default     = "Tofu-managed observability user"
}

variable "user_role" {
  description = "Rôle OpenStack du user. 'objectstore_operator' suffit pour S3."
  type        = string
  default     = "objectstore_operator"
}
