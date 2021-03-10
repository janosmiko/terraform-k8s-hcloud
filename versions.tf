terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    tls    = {
      source = "hashicorp/tls"
    }
    local  = {
      source = "hashicorp/local"
    }
  }
  required_version = ">= 0.14"
}
