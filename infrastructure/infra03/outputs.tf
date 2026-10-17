output "ipv4" {
  value = hcloud_server.this.ipv4_address
}

output "ipv6" {
  value = hcloud_server.this.ipv6_address
}

output "hostname" {
  value = var.manage_dns ? "${local.name}.${var.dns_zone}" : hcloud_server.this.ipv4_address
}

output "grafana_url" {
  value = "https://grafana.${local.name}.${var.dns_zone}"
}

output "tenant_domains" {
  description = "BASE_DOMAIN à écrire dans le .env de chaque instance."
  value       = { for tenant, zone in var.tenants : tenant => "staging.${zone}" }
}

output "backup_bucket" {
  value = var.manage_s3 ? module.backup_bucket[0].bucket_names["backups"] : null
}

output "ansible_inventory_hint" {
  description = "À reporter dans ~/work/ansible/inventories/infra03/hosts.yml."
  value       = "ansible_host: ${hcloud_server.this.ipv4_address}"
}
