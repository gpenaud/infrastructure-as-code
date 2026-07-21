#!/usr/bin/env bash
# Sync les buckets k8up actifs vers la nouvelle nomenclature alter-it-infra01-*
# Préserve les anciens buckets (PAS de delete)

set -euo pipefail

ENDPOINT="https://s3.sbg.io.cloud.ovh.net"

# Mapping source → destination
# Format : "ancien_bucket|nouveau_bucket"
declare -a MIGRATIONS=(
  "backup-srv1515851-ferme-du-jointout-dolibarr|alter-it-infra01-backup-ferme-du-jointout-dolibarr"
  "backup-srv1515851-ferme-du-jointout-nextcloud|alter-it-infra01-backup-ferme-du-jointout-nextcloud"
  "backup-srv1515851-la-bergeronnette-wordpress-site|alter-it-infra01-backup-la-bergeronnette-wordpress-site"
  "backup-srv1515851-le-portail-alterconso|alter-it-infra01-backup-le-portail-alterconso"
  "backup-srv1515851-le-portail-dolibarr|alter-it-infra01-backup-le-portail-dolibarr"
  "backup-srv1515851-le-portail-grist|alter-it-infra01-backup-le-portail-grist"
  "backup-srv1515851-le-portail-wordpress-epilibres|alter-it-infra01-backup-le-portail-wordpress-epilibres"
  "backup-srv1515851-le-portail-wordpress-site|alter-it-infra01-backup-le-portail-wordpress-site"
)

# Vérification : credentials S3 présents
if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
  echo "ERREUR : exporte AWS_ACCESS_KEY_ID et AWS_SECRET_ACCESS_KEY avant de lancer le script"
  exit 1
fi

echo "=== Sync de ${#MIGRATIONS[@]} buckets ==="
echo

for migration in "${MIGRATIONS[@]}"; do
  src="${migration%|*}"
  dst="${migration#*|}"
  
  echo "▶ $src"
  echo "  → $dst"
  
  # Vérifier que la source existe
  if ! aws s3api head-bucket --bucket "$src" --endpoint-url="$ENDPOINT" 2>/dev/null; then
    echo "  ⚠ Source absente, skip"
    echo
    continue
  fi
  
  # Vérifier que la destination existe (créée par Tofu)
  if ! aws s3api head-bucket --bucket "$dst" --endpoint-url="$ENDPOINT" 2>/dev/null; then
    echo "  ⚠ Destination absente — Tofu a-t-il bien créé le bucket ?"
    echo "  Skip"
    echo
    continue
  fi
  
  # Compter les objets source AVANT
  src_count=$(aws s3 ls "s3://$src/" --recursive --endpoint-url="$ENDPOINT" | wc -l)
  echo "  Source : $src_count objets"
  
  # Sync (--no-progress pour ne pas spammer, mais on a un summary à la fin)
  aws s3 sync "s3://$src/" "s3://$dst/" \
    --endpoint-url="$ENDPOINT" \
    --no-progress
  
  # Compter les objets destination APRÈS
  dst_count=$(aws s3 ls "s3://$dst/" --recursive --endpoint-url="$ENDPOINT" | wc -l)
  echo "  Destination : $dst_count objets"
  
  if [ "$src_count" -eq "$dst_count" ]; then
    echo "  ✅ OK"
  else
    echo "  ⚠ ATTENTION : nombre d'objets différent (src=$src_count vs dst=$dst_count)"
    echo "  → vérifier manuellement avant de continuer"
  fi
  
  echo
done

echo "=== Terminé ==="