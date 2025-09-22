locals {
  ip_addresses = { for name, vm in module.pve_pools: name => vm.ip_addresses }

  pools_size = [
    for name, pool in var.groups:
      pool.size > pool.reserved ? pool.size : pool.reserved
  ]

  pools_pos = {
    for ind, name in keys(var.groups):
      name => var.start_id + sum(ind > 0 ? [ for i in range(ind): local.pools_size[i] ] : [ 0 ])
  }

  all_hosts_to_group_list = flatten([
    for name, pool in module.pve_pools:
      [ for addr in pool.ip_addresses: { addr = addr, group = name, } ]
  ])
  all_hosts_to_group_map = { for obj in local.all_hosts_to_group_list: obj.addr => obj.group }

  control_group_name = one([for name, group in var.groups: name if group.is_control])
  worker_groups = setsubtract(keys(var.groups), [local.control_group_name])
}

module "pve_pools" {
  source = "../pve_pool"

  for_each = var.groups

  name     = "k8s-${each.key}-nodes"
  vms_name = "k8s-${each.key}-node"
  tags     = [ "K8S-cluster", "k8s-${each.key}-nodes" ]
  size     = each.value.size
  auth     = var.auth
  agent_on = true
  start_id = local.pools_pos[each.key]
  node     = var.node

  description = "K8S cluster nodes from the ${each.key} group"

  base    = var.base

  network = {
    cidr   = var.network.cidr
    dns    = [ var.network.dns ]
    domain = var.network.domain

    acls = [
      { cidr = "0.0.0.0/0", ports = "0:65535", proto = "tcp", policy = "accept", },
      { cidr = "0.0.0.0/0", ports = "0:65535", proto = "udp", policy = "accept", },
    ]
  }
  
  resources = {
    cpu    = each.value.resources.cpu
    memory = each.value.resources.memory
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

resource "ansible_group" "k8s_groups" {
  for_each = var.groups

  name = each.key
}

resource "ansible_group" "k8s" {
  name = "K8S"

  children = [ for group in ansible_group.k8s_groups: group.name ]
}

resource "ansible_host" "k8s_hosts" {
  for_each = local.all_hosts_to_group_map

  name   = each.key
  groups = [ ansible_group.k8s_groups[each.value].name ]
}

resource "ansible_playbook" "control" {
  count = local.control_group_name == null ? 0 : 1
  
  playbook = "${path.module}/playbooks/control.yml"
  name     = local.ip_addresses[local.control_group_name][0]
}

resource "ansible_playbook" "workers" {
  for_each = local.worker_groups
  
  playbook = "${path.module}/playbooks/workers.yml"
  name     = local.ip_addresses[each.value][0]
}
