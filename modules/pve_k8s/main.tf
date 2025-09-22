locals {
  ip_addresses = { for name, vm in module.pve_pools: name => vm.ip_addresses }

  pools_size = [
    for name, pool in var.groups:
      pool.size > pool.reserved ? pool.size : pool.reserved
  ]

  pools_pos = {
    for ind, name in keys(var.groups):
      name => var.start_id + sum([ for i in range(ind): local.pools_size[i] ])
  }

  all_hosts_to_group = flatten([
    for name, pool in module.pve_pools:
      [ for addr in pool.ip_addresses: { addr = addr, group = name, } ]
  ])

  control_group_name = one([for name, group in var.groups: name if group.is_control])
  worker_groups = setsubtract(keys(var.groups), [local.control_group_name])
}

module "pve_pools" {
  source = "../pve_pool"

  for_each = var.groups

  name     = "${each.key}-nodes"
  vms_name = each.value.name 
  tags     = [ "K8S-cluster", "${each.key}-nodes" ]
  size     = each.value.size
  auth     = var.auth
  agent_on = true
  start_id = local.pools_pos[each.key]

  description = "K8S cluster nodes from the ${each.key} group"

  base    = var.base

  network = {
    cidr   = var.network.cidr
    dns    = [ var.network.dns ]
    domain = var.network.domain

    acls = [
      { cidr = "0.0.0.0/0", ports = "1-65536", proto = "tcp", policy = "accept", },
      { cidr = "0.0.0.0/0", ports = "1-65536", proto = "udp", policy = "accept", },
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

resource "ansible_group" "k8s_groups" {
  for_each = var.groups

  name = each.key
}

resource "ansible_group" "k8s" {
  name = "K8S"

  children = ansible_group.k8s_groups[*].name
}

resource "ansible_host" "k8s_hosts" {
  for_each = local.all_hosts_to_group

  name   = each.value.addr
  groups = [ ansible_group.k8s_groups[each.value.group].name ]
}

resource "ansible_playbook" "control" {
  playbook = "${path.module}/playbooks/k8s/control.yml"
  name     = local.ip_addresses[local.control_group_name][0]
}

resource "ansible_playbook" "workers" {
  for_each = local.worker_groups
  
  playbook = "${path.module}/playbooks/k8s/workers.yml"
  name     = local.ip_addresses[each.value][0]
}
