variable "hcloud_token" {
}

variable "name" {
  default = "k8s"
}

variable "master_count" {
  default = 1
  validation {
    condition     = var.master_count == 1 || var.master_count >= 3
    error_message = "Should be exactly 1 or (3 or more)."
  }
}

variable "master_image" {
  description = "Predefined Image that will be used to spin up the machines"
  default     = "ubuntu-20.04"
}

variable "master_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx21"
}

variable "node_count" {
  default = 2
}

variable "node_image" {
  description = "Predefined Image that will be used to spin up the machines"
  default     = "ubuntu-20.04"
}

variable "node_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx21"
}

variable "public_key" {
  description = "Public Key to authorized the access for the machines"
  default     = ""
  #default     = "~/.ssh/id_rsa.pub"
}
variable "private_key" {
  default = "~/.ssh/id_rsa"
}

variable "key_name" {
  default = ""
}

variable "docker_version" {
  default = "19.03"
}

variable "kubernetes_version" {
  default = "1.20.4"
}

variable "feature_gates" {
  description = "Add Feature Gates e.g. 'DynamicKubeletConfig=true'"
  default     = ""
}

variable "calico_enabled" {
  default = true
}

variable "location" {
  default = "nbg1"
}

variable "ufw_enabled" {
  default = true
}

variable "ufw_allowed_ips" {
  type    = list(string)
  default = []
}
variable "load_balancer_api_server_listen_port" {
  default = 6443
}

variable "network_cidr" {
  default = "10.0.0.0/8"
}

variable "pod_network_cidr" {
  default = "10.244.0.0/16"
}

variable "node_network_cidr" {
  default = "10.8.0.0/16"
}

variable "csi_driver_enabled" {
  default = true
}

variable "hcloud_controller_manager_enabled" {
  default = true
}
