ephemeral "vault_kv_secret_v2" "proxmox_creds" {
  mount = "infra-secrets"
  name = "proxmox/creds"
}

locals {
  vault_proxmox = ephemeral.vault_kv_secret_v2.proxmox_creds.data
  proxmox_user  = local.vault_proxmox.username
  proxmox_pass  = local.vault_proxmox.password
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true

  username = local.proxmox_user
  password = local.proxmox_pass
}

module "pve_k8s" {
  source = "./modules/pve_k8s"

  network = {
    cidr   = "192.168.0.0/24"
    dns    = "8.8.8.8"
    domain = "cluster.local"
  }

  start_id = 100
  node     = "pve"

  auth = {
    user = "user"
    pass = "$5$C.6CsFKu0G6.tRIc$ciI0ED17SzFKA10agSTe87SnfLQ32q9iu8sq3ivt0R9"
    ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK0yO9RABzbP4OhuNYjjAo+xtwyVUHsg9sbIQxhYIFMp space@space"
    ]
  }

  groups = {
    control = {
      size       = 1
      node_name  = "control-node"
      is_control = true
      reserved   = 2

      resources = {
        cpu    = 4
        memory = 8         
      }
    }
    worker = {
      size      = 1
      node_name = "worker-node"
      reserved  = 2

      resources = {
        cpu    = 4
        memory = 8
      }
    }
  }
}

output "ansible_logs" {
  description = "Location of the ansible playbook launch logs"

  value = module.pve_k8s.ansible_logs
}
