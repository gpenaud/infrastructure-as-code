#!/usr/bin/env bash
#
# upload-talos-image.sh
#
# Pousse une image Talos comme snapshot Hetzner via hcloud-upload-image.
# Opération one-shot, hors Tofu. À relancer uniquement pour bumper Talos.
# Le selector côté Tofu (os=talos,talos-version=...) résout le snapshot récent.
#
# Prérequis : hcloud-upload-image, curl, jq, HCLOUD_TOKEN exporté.

set -euo pipefail

TALOS_VERSION="${TALOS_VERSION:-v1.9.5}"
: "${HCLOUD_TOKEN:?Il faut exporter HCLOUD_TOKEN}"

echo ">> Génération du schematic (qemu-guest-agent)..."
SCHEMATIC_ID=$(curl -sX POST --data-binary @- https://factory.talos.dev/schematics <<'EOF' | jq -r .id
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/qemu-guest-agent
      - siderolabs/iscsi-tools
      - siderolabs/util-linux-tools
      - siderolabs/lvm2
EOF
)
echo "   schematic id = ${SCHEMATIC_ID}"

IMAGE_URL="https://factory.talos.dev/image/${SCHEMATIC_ID}/${TALOS_VERSION}/hcloud-amd64.raw.xz"
echo ">> URL image = ${IMAGE_URL}"

echo ">> Upload du snapshot Talos ${TALOS_VERSION}..."
hcloud-upload-image upload \
  --image-url "${IMAGE_URL}" \
  --compression xz \
  --server-type cx23 \
  --labels "os=talos,talos-version=${TALOS_VERSION}"

echo ">> Terminé. Snapshot étiqueté os=talos,talos-version=${TALOS_VERSION}."
