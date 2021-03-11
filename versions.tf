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
    time   = {
      source = "hashicorp/time"
    }
  }
  required_version = ">= 0.14"
}
