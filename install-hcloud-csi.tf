resource "null_resource" "hcloud-csi" {
  count = var.csi_driver_enabled ? 1 : 0

  connection {
    host        = hcloud_server.master.0.ipv4_address
    private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install-hcloud-csi.sh"
    destination = "/root/install-hcloud-csi.sh"
  }

  provisioner "remote-exec" {
    inline = ["HCLOUD_TOKEN=${var.hcloud_token} bash /root/install-hcloud-csi.sh"]
  }

  depends_on = [hcloud_server.master]
}

