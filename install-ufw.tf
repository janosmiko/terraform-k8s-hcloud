resource "null_resource" "ufw-master" {
  count = var.ufw_enabled ? length(hcloud_server.master) : 0

  connection {
    host        = hcloud_server.master[count.index].ipv4_address
    private_key = file(var.ssh_private_key)
  }

  provisioner "file" {
    source      = "scripts/master-ufw.sh"
    destination = "/root/master-ufw.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/master-ufw.sh"]
  }

  depends_on = [hcloud_server.master]
}


resource "null_resource" "ufw-node" {
  count = var.ufw_enabled ? length(hcloud_server.node) : 0

  connection {
    host        = hcloud_server.node[count.index].ipv4_address
    private_key = file(var.ssh_private_key)
  }

  provisioner "file" {
    source      = "scripts/node-ufw.sh"
    destination = "/root/node-ufw.sh"
  }

  # TODO: Fix multiple master ufw rules for nodes
  provisioner "remote-exec" {
    inline = ["MASTER_IP=${hcloud_server.master[0].ipv4_address} bash /root/node-ufw.sh"]
  }

  depends_on = [hcloud_server.master]
}