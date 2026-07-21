#!/usr/bin/env bash
#
# render-cilium.sh
#
# Rend le chart Cilium en YAML statique pour l'injecter dans les inlineManifests
# de Talos (approche C : Talos pose Cilium au bootstrap, avant tout le reste).
#
# Le YAML produit est consommé par talos.tf (data.local_file). À relancer si tu
# changes la version de Cilium ou les values.
#
# Prérequis : helm, et cilium-values.yaml dans le répertoire parent.

set -euo pipefail

CILIUM_VERSION="${CILIUM_VERSION:-1.16.5}"
OUT="${OUT:-./manifests/cilium.yaml}"
VALUES="${VALUES:-./cilium-values.yaml}"

mkdir -p "$(dirname "$OUT")"

helm repo add cilium https://helm.cilium.io >/dev/null 2>&1 || true
helm repo update cilium >/dev/null

echo ">> Rendu de Cilium ${CILIUM_VERSION} vers ${OUT}..."
helm template cilium cilium/cilium \
  --version "${CILIUM_VERSION}" \
  --namespace kube-system \
  --values "${VALUES}" \
  > "${OUT}"

echo ">> Fait. $(grep -c '^kind:' "${OUT}") ressources rendues."
echo "   (relance 'tofu apply' pour pousser la nouvelle config Talos)"

aws s3 cp manifests/cilium.yaml s3://alter-it-bootstrap-resources/talos/cilium.yaml \
  --endpoint-url https://s3.sbg.io.cloud.ovh.net \
  --acl public-read

bash ../../modules/talos-hetzner/upload-talos-image.sh