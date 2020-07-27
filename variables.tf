variable "hcloud_token" {
}

variable "master_count" {
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
}

variable "node_image" {
  description = "Predefined Image that will be used to spin up the machines"
  default     = "ubuntu-20.04"
}

variable "node_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx21"
}

variable "ssh_private_key" {
  description = "Private Key to access the machines"
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_public_key" {
  description = "Public Key to authorized the access for the machines"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "docker_version" {
  default = "19.03"
}

variable "kubernetes_version" {
  default = "1.18.6"
}

variable "feature_gates" {
  description = "Add Feature Gates e.g. 'DynamicKubeletConfig=true'"
  default     = ""
}

variable "calico_enabled" {
  default = false
}

variable "location" {
  default = "nbg1"
}

variable "ufw_enabled" {
  default = false
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
  default = false
}