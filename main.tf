provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_load_balancer" "api_server" {
  count              = var.master_count > 1 ? 1 : 0
  name               = "${var.name}-api-endpoint"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_service" "api" {
  count            = var.master_count > 1 ? 1 : 0
  load_balancer_id = hcloud_load_balancer.api_server[count.index].id
  protocol         = "tcp"
  listen_port      = var.load_balancer_api_server_listen_port
  destination_port = 6443
  health_check {
    interval = 5
    timeout  = 3
    retries  = 3
    port     = 6443
    protocol = "tcp"
  }
}

#module "tls" {
#  source              = "./tls"
#  master_lb_public_ip = hcloud_load_balancer.api_server.ipv4
#}

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

resource "time_sleep" "wait_120_seconds" {
  depends_on = [hcloud_network_subnet.node]

  destroy_duration = "120s"
}

resource "hcloud_load_balancer_target" "master" {
  count            = var.master_count > 1 ? 1 : 0
  load_balancer_id = hcloud_load_balancer.api_server[0].id
  label_selector   = "k8s-role=master,k8s-cluster=${var.name}"
  type             = "label_selector"
}

resource "hcloud_server" "master" {
  count       = 1
  name        = "${var.name}-master-${count.index + 1}"
  server_type = var.master_type
  image       = var.master_image
  ssh_keys    = [hcloud_ssh_key.this.id]
  location    = var.location
  labels      = {
    k8s-cluster = var.name
    k8s-role    = "master"
  }
  network {
    network_id = hcloud_network.this.id
  }
  depends_on  = [
    time_sleep.wait_120_seconds
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
      "export DOCKER_VERSION=${var.docker_version}",
      "export KUBERNETES_VERSION=${var.kubernetes_version}",
      "bash /root/bootstrap.sh"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/master.sh"
    destination = "/root/master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export FEATURE_GATES=${var.feature_gates}",
      "export POD_NETWORK_CIDR=${var.pod_network_cidr}",
      var.master_count > 1 ? "export MULTI_MASTER=true" : "export MULTI_MASTER=false",
      var.master_count > 1 ? "export LOAD_BALANCER_DNS=${hcloud_load_balancer.api_server[0].ipv4}" : "export LOAD_BALANCER_DNS=''",
      var.master_count > 1 ? "export LOAD_BALANCER_PORT=${hcloud_load_balancer_service.api[0].listen_port}" : "export LOAD_BALANCER_PORT=''",
      "bash /root/master.sh"]
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

module "kubeadm_master_join" {
  source = "matti/resource/shell"

  depends = [
    hcloud_server.master
  ]

  command = "cat ${path.module}/secrets/kubeadm_master_join"

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

resource "hcloud_server" "secondary_masters" {
  count       = var.master_count - 1
  name        = "${var.name}-master-${count.index + 2}"
  server_type = var.master_type
  image       = var.master_image
  ssh_keys    = [hcloud_ssh_key.this.id]
  location    = var.location
  labels      = {
    k8s-cluster = var.name
    k8s-role    = "master"
  }

  network {
    network_id = hcloud_network.this.id
  }
  depends_on = [
    hcloud_network_subnet.node,
    hcloud_server.master
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
    source      = "${path.module}/secrets/kubeadm_master_join"
    destination = "/tmp/kubeadm_master_join"

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = var.public_key == "" ? tls_private_key.this[0].private_key_pem : file(var.private_key)
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/secondary_master.sh"
    destination = "/root/secondary_master.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/secondary_master.sh"]
  }
}

resource "hcloud_server" "node" {
  count       = var.node_count
  name        = "${var.name}-node-${count.index + 1}"
  server_type = var.node_type
  image       = var.node_image
  ssh_keys    = [hcloud_ssh_key.this.id]
  location    = var.location
  labels      = {
    k8s-cluster = var.name
    k8s-role    = "node"
  }

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
