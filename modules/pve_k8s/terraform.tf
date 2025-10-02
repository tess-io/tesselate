terraform {
  required_version = ">= 1.13.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.83.0"
    }
    
    ansible = {
      source  = "ansible/ansible"
      version = ">= 1.3.0"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}
