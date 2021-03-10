provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "this" {
  count     = var.public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  sensitive_content = tls_private_key.this[0].private_key_pem
  filename          = "${path.module}/secrets/id_rsa"
  file_permission   = "0600"
}

resource "hcloud_ssh_key" "this" {
  name       = var.key_name == "" ? "${var.name}-key" : var.key_name
  public_key = var.public_key == "" ? tls_private_key.this[0].public_key_openssh : var.public_key
}

resource "hcloud_network" "this" {
  name     = "${var.name}-net"
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "node" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.node_network_cidr
}

resource "hcloud_server" "master" {
  count       = var.master_count
  name        = "${var.name}-master-${count.index + 1}"
  server_type = var.master_type
  image       = var.master_image
  ssh_keys    = [hcloud_ssh_key.this.id]
  location    = var.location
  network {
    network_id = hcloud_network.this.id
  }
  depends_on  = [
    hcloud_network_subnet.node
  ]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/files/10-kubeadm.conf"
    destination = "/root/10-kubeadm.conf"
  }

  provisioner "file" {
    source      = "${path.module}/files/resolv.conf"
    destination = "/etc/resolv_hetzer.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "DOCKER_VERSION=${var.docker_version} KUBERNETES_VERSION=${var.kubernetes_version} bash /root/bootstrap.sh"]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/master.sh"
    destination = "/root/master.sh"
  }

  provisioner "remote-exec" {
    inline = ["FEATURE_GATES=${var.feature_gates} POD_NETWORK_CIDR=${var.pod_network_cidr} bash /root/master.sh"]
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/copy-kubeadm-token.sh"

    environment = {
      SSH_PRIVATE_KEY = var.public_key == "" ? local_file.private_key.filename : file(var.private_key)
      SSH_USERNAME    = "root"
      SSH_HOST        = hcloud_server.master[0].ipv4_address
      TARGET          = "${path.module}/secrets/"
    }
  }
}

module "kubeadm_join" {
  source = "matti/resource/shell"

  depends = [
    hcloud_server.master
  ]

  command = "cat ${path.module}/secrets/kubeadm_join"

  depends_on = [
    hcloud_server.master
  ]
}

module "admin_conf" {
  source = "matti/resource/shell"

  command = "cat ${path.module}/secrets/admin.conf"

  depends_on = [
    hcloud_server.master
  ]
}

resource "hcloud_server" "node" {
  count       = var.node_count
  name        = "${var.name}-node-${count.index + 1}"
  server_type = var.node_type
  image       = var.node_image
  ssh_keys    = [hcloud_ssh_key.this.id]
  location    = var.location

  network {
    network_id = hcloud_network.this.id
  }
  depends_on = [
    hcloud_server.master,
    hcloud_network_subnet.node
  ]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/files/resolv.conf"
    destination = "/etc/resolv_hetzer.conf"
  }

  provisioner "file" {
    source      = "${path.module}/files/10-kubeadm.conf"
    destination = "/root/10-kubeadm.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "DOCKER_VERSION=${var.docker_version} KUBERNETES_VERSION=${var.kubernetes_version} bash /root/bootstrap.sh"]
  }

  provisioner "file" {
    source      = "${path.module}/secrets/kubeadm_join"
    destination = "/tmp/kubeadm_join"

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/node.sh"
    destination = "/root/node.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/node.sh"]
  }

}

#resource "hcloud_server_network" "master_network" {
#  count = length(hcloud_server.master)

#  server_id  = hcloud_server.master[count.index].id
#  network_id = hcloud_network.this.id
#}

#resource "hcloud_server_network" "node_network" {
#  count = length(hcloud_server.node)

#  server_id  = hcloud_server.node[count.index].id
#  network_id = hcloud_network.this.id
#}
