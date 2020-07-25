provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "k8s_admin" {
  name       = "k8s_admin"
  public_key = file(var.ssh_public_key)
}

resource "hcloud_network" "k8s-net" {
  name = "k8s-net"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "node-net" {
  network_id = "${hcloud_network.k8s-net.id}"
  type = "cloud"
  network_zone = "eu-central"
  ip_range   = "10.8.0.0/16"
}

resource "hcloud_network_subnet" "pod-net" {
  network_id = "${hcloud_network.k8s-net.id}"
  type = "cloud"
  network_zone = "eu-central"
  ip_range   = "10.244.0.0/16"
}

resource "hcloud_server" "master" {
  count       = var.master_count
  name        = "master-${count.index + 1}"
  server_type = var.master_type
  image       = var.master_image
  ssh_keys    = [hcloud_ssh_key.k8s_admin.id]
  location    = var.location

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    private_key = file(var.ssh_private_key)
  }

  provisioner "file" {
    source      = "files/10-kubeadm.conf"
    destination = "/root/10-kubeadm.conf"
  }

  provisioner "file" {
    source      = "files/resolv.conf"
    destination = "/etc/resolv_hetzer.conf"
  }

  provisioner "file" {
    source      = "scripts/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = ["DOCKER_VERSION=${var.docker_version} KUBERNETES_VERSION=${var.kubernetes_version} bash /root/bootstrap.sh"]
  }

  provisioner "file" {
    source      = "scripts/master.sh"
    destination = "/root/master.sh"
  }

  provisioner "remote-exec" {
    inline = ["FEATURE_GATES=${var.feature_gates} POD_NETWORK_CIDR=${var.pod_network_cidr} bash /root/master.sh"]
  }

  provisioner "local-exec" {
    command = "bash scripts/copy-kubeadm-token.sh"

    environment = {
      SSH_PRIVATE_KEY = var.ssh_private_key
      SSH_USERNAME    = "root"
      SSH_HOST        = hcloud_server.master[0].ipv4_address
      TARGET          = "${path.module}/secrets/"
    }
  }
}

resource "hcloud_server" "node" {
  count       = var.node_count
  name        = "node-${count.index + 1}"
  server_type = var.node_type
  image       = var.node_image
  depends_on  = [hcloud_server.master]
  ssh_keys    = [hcloud_ssh_key.k8s_admin.id]
  location    = var.location

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    private_key = file(var.ssh_private_key)
  }

  provisioner "file" {
    source      = "files/resolv.conf"
    destination = "/etc/resolv_hetzer.conf"
  }

  provisioner "file" {
    source      = "files/10-kubeadm.conf"
    destination = "/root/10-kubeadm.conf"
  }

  provisioner "file" {
    source      = "scripts/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = ["DOCKER_VERSION=${var.docker_version} KUBERNETES_VERSION=${var.kubernetes_version} bash /root/bootstrap.sh"]
  }

  provisioner "file" {
    source      = "${path.module}/secrets/kubeadm_join"
    destination = "/tmp/kubeadm_join"

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source      = "scripts/node.sh"
    destination = "/root/node.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/node.sh"]
  }
}

resource "hcloud_server_network" "master_network" {
  count = length(hcloud_server.master)

  server_id = "${hcloud_server.master[count.index].id}"
  network_id = "${hcloud_network.k8s-net.id}"
}

resource "hcloud_server_network" "node_network" {
  count = length(hcloud_server.node)

  server_id = "${hcloud_server.node[count.index].id}"
  network_id = "${hcloud_network.k8s-net.id}"
}