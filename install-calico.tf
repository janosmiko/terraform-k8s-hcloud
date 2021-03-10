resource "null_resource" "calico" {
  count = var.calico_enabled ? 1 : 0

  connection {
    host        = hcloud_server.master.0.ipv4_address
    private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"]
  }

  depends_on = [hcloud_server.master]
}

