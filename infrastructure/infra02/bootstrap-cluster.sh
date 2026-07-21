#!/usr/bin/env bash

FLUX_FLEET_REPOSITORY_PATH=~/work/flux-fleet
CLUSTER_VARS_FILE=${FLUX_FLEET_REPOSITORY_PATH}/clusters/infra02/cluster-vars/configmap.yaml

tofu output -raw talosconfig > ~/.talos/config
tofu output -raw kubeconfig > ~/.k3s/kubeconfigs/infra02

cluster_endpoint=$(tofu output -raw cluster_endpoint | sed -E 's#https://([0-9.]+):.*#\1#')
sed -i -E "s#^([[:space:]]*cluster_endpoint_ip:[[:space:]]*).*#\1${cluster_endpoint}#" ${CLUSTER_VARS_FILE}

source ~/.bashrc
kubectl config use-context admin@infra02

# flux --context "admin@infra02" --namespace flux-system create secret githubapp flux-system \
#   --app-id=2617634 \
#   --app-installation-id= \
#   --app-private-key={{ github_app_private_key_file_path }}

# source PAT token
export GITHUB_USER=gpenaud
export GITHUB_TOKEN=$(cat ~/.github/repository)

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=flux-fleet \
  --branch=feature/cleaned-organisation \
  --path=clusters/infra02 \
  --personal

cat ~/.config/sops/age/keys.txt | kubectl -n flux-system create secret generic sops-age-private-key --from-file=age.agekey=/dev/stdin