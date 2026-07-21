# ─────────────────────────────────────────────────────────────────────────────
# Image Talos
#
# Le snapshot Talos est poussé HORS Tofu, une seule fois, via hcloud-upload-image
# (voir scripts/upload-talos-image.sh). Tofu se contente de le RÉFÉRENCER ici.
#
# Aucune ressource builder : pas de serveur rescue, pas de null_resource, pas de
# clé SSH éphémère. Juste la résolution du snapshot par ses labels.
# ─────────────────────────────────────────────────────────────────────────────

data "hcloud_image" "talos" {
  with_selector     = "os=talos,talos-version=${var.talos_version}"
  with_architecture = "x86"
  most_recent       = true
}
