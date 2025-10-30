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

  playbooks_dir = var.playbooks_dir != null ? var.playbooks_dir : "${path.root}/playbooks"
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
  playbook = "tesselate.k8s.k8s_controls"
  name     = local.about[local.control_group_name][0].ip_address

  diff_mode = true
  verbosity = 1

  tags = [ "common", "init" ]

  extra_vars = {
    ansible_user          = var.auth.user
    ansible_become_method = local.become_methods[var.base.os]

    k8s_ca_crt     = var.cert.ca
    k8s_ca_key     = var.cert.key
    k8s_pod_cidr   = "172.16.0.0/16"

    state = "init"

    save_kubeconfig_to = var.kubeconfig_path
  }
}

resource "ansible_playbook" "control_join" {
  count = length(local.control_group_machines) - 1
  
  playbook = "tesselate.k8s.k8s_controls"
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
  
  playbook = "tesselate.k8s.k8s_workers"
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
  
  playbook = "tesselate.k8s.k8s_labels"
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
    ansible_playbook.control_join,
    ansible_playbook.workers,
  ]
}

resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  chart      = "cilium"
  repository = "https://helm.cilium.io" 

  set = [
    { name = "version", value = "1.16.5" },
    { name = "cgroup.autoMount.enabled", value = "false" },
    { name = "cgroup.hostRoot", value = "/sys/fs/cgroup" },
    { name = "operator.replicas", value = "1" },
    { name = "ipam.operator.clusterPoolIPv4PodCIDRList", value = "172.16.0.0/16" },
    { name = "k8sServicePort", value = "10248" },
    { name = "ipam-mode", value = "cluster-pool" },
    { name = "cni.binPath", value = "/usr/libexec/cni" },
  ]


  depends_on = [
    ansible_playbook.control_init,
    ansible_playbook.control_join,
    ansible_playbook.workers,
  ]
}
