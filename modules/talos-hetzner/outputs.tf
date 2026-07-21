output "talosconfig" {
  description = "Configuration client talosctl. Sauvegarde dans ~/.talos/config."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig du cluster. Sauvegarde dans ~/.kube/config."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Endpoint de l'API Kubernetes (via le Load Balancer)."
  value       = local.cluster_endpoint
}

output "node_ips" {
  description = "IPs publiques de tous les nœuds."
  value       = hcloud_server.node[*].ipv4_address
}
