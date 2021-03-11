output "node_ips" {
  value = hcloud_server.node.*.ipv4_address
}

output "master_ips" {
  value = hcloud_server.master.*.ipv4_address
}

output "master_endpoint" {
  value = var.master_count > 1 ? hcloud_load_balancer.api_server[0].ipv4 : ""
}

output "k8s_config" {
  value = module.admin_conf.stdout
}
