ephemeral "vault_kv_secret_v2" "proxmox_creds" {
  mount = "infra-secrets"
  name  = "proxmox/creds"
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

module "vm_pools" {
  for_each = {
    redis = {
      name        = "redis-ha"
      vms_name    = "redis-srv"
      description = "Redis HA VMs pool"
      tags        = [ "redis", "production", ]
      start_id    = 100
      size        = 3

      base = {
        os      = "alpine"
        version = "3.21.0"
        arch    = "x86_64"
      }

      acls = [
        { cidr = "0.0.0.0", ports = "22,80,443", policy = "accept", proto = "tcp", },
      ]
    }

    mongo = {
      name        = "mongo-ha"
      vms_name    = "mongo-srv"
      description = "Mongo cluster VMs pool"
      tags        = [ "mongo", "production", ]
      start_id    = 103
      size        = 3

      base = {
        os      = "ubuntu"
        version = "noble"
        arch    = "x86_64"
      }

      acls = [
        { cidr = "0.0.0.0", ports = "22,80,443", policy = "accept", proto = "tcp", },
      ]
    }
  }
  
  source = "./modules/pve_pool"

  name        = each.value.name
  vms_name    = each.value.vms_name
  description = each.value.description
  tags        = each.value.tags
  start_id    = each.value.start_id

  agent_on = true
  node     = "pve"
  size     = each.value.size

  auth = {
    user     = "user"
    pass     = "$5$AGuU1Ws8C18XnI1r$s.5V.LE6HS/242LDQKPcROjfRkH1cpHNnDG7v/T/EkD"
    ssh_keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK0yO9RABzbP4OhuNYjjAo+xtwyVUHsg9sbIQxhYIFMp" ]
  }

  resources = {
    cpu    = 8
    memory = 8
    hugepg = false
  }

  base = {
    os      = "alpine"
    version = "3.21.0"
    arch    = "x86_64"
  }

  network = {
    cidr   = "192.168.0.0/24"
    dns    = [ "8.8.8.8" ]
    domain = "local"
    acls   = each.value.acls
  }

  disks = {
    root      = { storage = "SSD", size = 8 },
    cloudinit = { storage = "SSD" },
    other     = [
      { storage = "SSD", size = 32, },
    ],
  }
}

output "ip_addresses" {
  value = { for name, vm in module.vm_pools: name => vm.ip_addresses }
}
