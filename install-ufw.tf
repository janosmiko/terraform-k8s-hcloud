resource "null_resource" "ufw-master" {
  count = var.ufw_enabled ? length(hcloud_server.master) : 0

  connection {
    host        = hcloud_server.master[count.index].ipv4_address
    private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/master-ufw.sh"
    destination = "/root/master-ufw.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eux",
      "export MASTER_IPS='${join(" ", hcloud_server.master.*.ipv4_address)}'",
      "export NODE_NETWORK_CIDR='${var.node_network_cidr}'",
      "export POD_NETWORK_CIDR='${var.pod_network_cidr}'",
      "export FIREWALL_ALLOWED_IPS='${join(" ", var.ufw_allowed_ips)}'",
      "bash /root/master-ufw.sh"]
  }

  depends_on = [hcloud_server.master]
}


resource "null_resource" "ufw-node" {
  count = var.ufw_enabled ? length(hcloud_server.node) : 0

  connection {
    host        = hcloud_server.node[count.index].ipv4_address
    private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/node-ufw.sh"
    destination = "/root/node-ufw.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eux",
      "export MASTER_IPS='${join(" ", hcloud_server.master.*.ipv4_address)}'",
      "export NODE_NETWORK_CIDR='${var.node_network_cidr}'",
      "export POD_NETWORK_CIDR='${var.pod_network_cidr}'",
      "export FIREWALL_ALLOWED_IPS='${join(" ", var.ufw_allowed_ips)}'",
      "bash /root/node-ufw.sh"
    ]
  }

  depends_on = [hcloud_server.master]
}
