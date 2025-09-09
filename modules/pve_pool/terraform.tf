
terraform {
  required_version = ">= 1.13.0"

  required_providers {
    proxmox = {
      source   = "bpg/proxmox"
      version  = ">= 0.83.0"
    }

    vault = {
      source   = "hashicorp/vault"
      version  = ">= 5.2.0"
    }
  }
}

