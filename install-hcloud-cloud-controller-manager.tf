resource "null_resource" "hcloud-cloud-controller-manager" {

  connection {
    host        = hcloud_server.master.0.ipv4_address
    private_key = file(var.ssh_private_key)
  }

  provisioner "file" {
    source      = "scripts/hcloud-cloud-controller-manager.sh"
    destination = "/root/hcloud-cloud-controller-manager.sh"
  }

  provisioner "remote-exec" {
    inline = ["HCLOUD_TOKEN=${var.hcloud_token} CLUSTER_NETWORK=${hcloud_network.k8s-net.id} bash /root/hcloud-cloud-controller-manager.sh"]
  }

  depends_on = [hcloud_server.master]
}

