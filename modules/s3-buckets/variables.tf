variable "buckets" {
  description = <<-EOT
    Map de buckets à créer. Clé = nom logique (pour les outputs),
    valeur = configuration du bucket.
    
    Exemple :
    {
      "loki-rules" = {
        name = "alter-it-infra01-platform-loki-rules"
        expiration_days = 0  # 0 = pas d'expiration
      }
    }
  EOT
  
  type = map(object({
    name            = string
    expiration_days = optional(number, 0)  # 0 = lifecycle désactivé
  }))
}

variable "common_tags" {
  description = "Tags appliqués à tous les buckets"
  type        = map(string)
  default     = {}
}
