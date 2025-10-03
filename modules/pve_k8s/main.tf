locals {
  about = { for name, pool in module.pve_pools: name => pool.about }

  pools_size = [
    for name, pool in var.groups:
      pool.size > pool.reserved ? pool.size : pool.reserved
  ]

  pools_pos = {
    for ind, name in keys(var.groups):
      name => var.start_id + sum(ind > 0 ? [ for i in range(ind): local.pools_size[i] ] : [ 0 ])
  }

  all_hosts_about_list = flatten([
    for name, pool in module.pve_pools:
      [ for about in pool.about: { about = about, group = name, } ]
  ])
  all_hosts_to_info_map = {
    for obj in local.all_hosts_about_list:
      obj.about.ip_address => {
        group = obj.group
        name  = obj.about.name
      }
  }

  control_group_name = one([for name, group in var.groups: name if group.is_control])
  worker_groups = setsubtract(keys(var.groups), [local.control_group_name])

  control_group_machines = [
    for addr, info in local.all_hosts_to_info_map:
      addr if info.group == local.control_group_name
  ]
  worker_groups_machines = {
    for addr, info in local.all_hosts_to_info_map:
      addr => info if info.group != local.control_group_name
  }

  become_methods = {
    alpine = "doas"
    ubuntu = "sudo"
  }
}

module "pve_pools" {
  source = "../pve_pool"

  for_each = var.groups

  name     = "k8s-${each.key}-nodes"
  vms_name = "${each.value.node_name}"
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

resource "ansible_playbook" "control_init" {
  playbook = "${path.root}/playbooks/k8s/control.yml"
  name     = local.about[local.control_group_name][0].ip_address

  diff_mode = true
  verbosity = 1

  tags = [ "common", "init" ]

  extra_vars = {
    ansible_user          = var.auth.user
    ansible_become_method = local.become_methods[var.base.os]

    k8s_ca_crt     = var.cert.ca
    k8s_ca_key     = var.cert.key

    state = "init"
  }
}

resource "ansible_playbook" "control_join" {
  count = length(local.control_group_machines) - 1
  
  playbook = "${path.root}/playbooks/k8s/control.yml"
  name     = local.about[local.control_group_name][count.index + 1].ip_address

  diff_mode = true
  verbosity = 1

  tags = [ "common", "join" ]

  extra_vars = {
    ansible_user          = var.auth.user
    ansible_become_method = local.become_methods[var.base.os]

    k8s_init_node  = local.about[local.control_group_name][0].ip_address
    k8s_ca_crt     = var.cert.ca
    k8s_ca_key     = var.cert.key

    state = "join"
  }

  depends_on = [
    ansible_playbook.control_init
  ]
}

resource "ansible_playbook" "workers" {
  for_each = local.worker_groups_machines
  
  playbook = "${path.root}/playbooks/k8s/workers.yml"
  name     = each.key

  diff_mode = true
  verbosity = 1

  extra_vars = {
    ansible_user          = var.auth.user
    ansible_become_method = local.become_methods[var.base.os]

    k8s_init_node  = local.about[local.control_group_name][0].ip_address
    k8s_ca_crt     = var.cert.ca
    k8s_ca_key     = var.cert.key
  }

  depends_on = [
    ansible_playbook.control_init,
  ]
}

resource "ansible_playbook" "labels" {
  for_each = local.worker_groups_machines
  
  playbook = "${path.root}/playbooks/k8s/labels.yml"
  name     = local.about[local.control_group_name][0].ip_address

  diff_mode = true
  verbosity = 1

  extra_vars = {
    ansible_user          = var.auth.user
    ansible_become_method = local.become_methods[var.base.os]

    node_name = each.value.name
    node_role = each.value.group
  }

  depends_on = [
    ansible_playbook.control_init,
    ansible_playbook.workers,
  ]
}
