resource "null_resource" "hcloud-cloud-controller-manager" {
  count = var.hcloud_controller_manager_enabled ? 1 : 0

  connection {
    host        = hcloud_server.master.0.ipv4_address
    private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/hcloud-cloud-controller-manager.sh"
    destination = "/root/hcloud-cloud-controller-manager.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "HCLOUD_TOKEN=${var.hcloud_token} CLUSTER_NETWORK=${hcloud_network.this.id} bash /root/hcloud-cloud-controller-manager.sh"]
  }

  depends_on = [hcloud_server.master, null_resource.calico]
}

