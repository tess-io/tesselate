module "pve_pool" {
  source = "../pve_pool"

  for_each = var.groups

  name     = "${each.key}-nodes"
  vms_name = each.value.name 
  tags     = [ "K8S-cluster", "${each.key}-nodes" ]
  size     = each.value.size
  auth     = var.auth
  agent_on = true

  description = "K8S cluster nodes from the ${each.key} group"

  base    = var.base

  network = {
    cidr   = var.network.cidr
    dns    = var.network.dns
    domain = var.network.domain

    acls = [
      { cidr = "0.0.0.0/0", ports = "1-65536", proto = "tcp", policy = "allow", },
      { cidr = "0.0.0.0/0", ports = "1-65536", proto = "udp", policy = "allow", },
    ]
  }
  
  resources = {
    cpu    = each.value.cpu
    memory = each.value.memory
    hugepg = false
  }

  disks = {
    root      = { storage = "SSD", size = 32 }
    cloudinit = { storage = "HDD" }
    other     = [
      { storage = "SSD", size = 32 }
    ]
  }
}
