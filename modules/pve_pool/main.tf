locals {
  helpers = {
    alpine = var.base.os == "alpine" ? {
      mm_version = "v${split(".", var.base.version)[0]}.${split(".", var.base.version)[1]}"
    } : null
    ubuntu = var.base.os == "ubuntu" ? {
      arch_replace = {
        x86_64  = "amd64",
        aarch64 = "arm64",
      }
    } : null
  }

  urls = {
    alpine = var.base.os == "alpine" ? "https://dl-cdn.alpinelinux.org/alpine/${local.helpers.alpine.mm_version}/releases/cloud/generic_alpine-${var.base.version}-x86_64-uefi-cloudinit-r0.qcow2" : null
    ubuntu = var.base.os == "ubuntu" ? "https://cloud-images.ubuntu.com/${var.base.version}/current/${var.base.version}-server-cloudimg-${local.helpers.ubuntu.arch_replace[var.base.arch]}.img" : null
  }

  img_version = {
    alpine = var.base.os == "alpine" ? "v${var.base.version}" : null
    ubuntu = var.base.os == "ubuntu" ? var.base.version : null
  }

  cidr = split("/", var.network.cidr)
  net_part = local.cidr[0]
  mask_part = local.cidr[1]
}

data "cloudinit_config" "cloudinit_pve" {
  count = var.size

  base64_encode = false
  gzip          = false

  part {
    content_type = "text/cloud-config"
    filename     = "base-cloud-config.yml"
    content      = templatefile("${path.module}/cloud-init/base-cloud-config.yml", {
      fqdn              = "${var.name}-${count.index}.${var.network.domain}"
      default_user      = var.auth.user,
      default_pass_hash = var.auth.pass,
      ssh_auth_keys     = var.auth.ssh_keys,
    })
  }

  part {
    content_type = "text/cloud-config"
    filename     = "pve-cloud-config.yml"
    content      = templatefile("${path.module}/cloud-init/pve-cloud-config.yml", {
      os            = var.base.os,
      nameservers   = var.network.dns,
      searchdomains = [ var.network.domain ],
      domain        = "${var.name}-${count.index}",
      agent_on      = var.agent_on
    })
  }
}

resource "proxmox_virtual_environment_file" "cloudinit_pve" {
  count = var.size
  
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node

  source_raw {
    data      = data.cloudinit_config.cloudinit_pve[count.index].rendered
    file_name = "${var.name}-${var.base.os}-cloudinit-pve-vm-${count.index}.yml"
  }
}

resource "proxmox_virtual_environment_download_file" "cloudinit_img" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node

  url       = local.urls[var.base.os]
  file_name = "${var.base.os}-${local.img_version[var.base.os]}-${var.base.arch}.qcow2"
}

resource "proxmox_virtual_environment_pool" "pool" {
  comment = var.description
  pool_id = var.name
}

resource "proxmox_virtual_environment_cluster_firewall_security_group" "sc" {
  name    = var.name
  comment = "Custom traffic filtering rules for a pool ${var.name}"

  dynamic "rule" {
    for_each = var.network.acls 

    content {
      type   = "in"
      action = upper(rule.value.policy)
      source = rule.value.cidr
      dport  = rule.value.ports
      proto  = rule.value.proto
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  count = var.size

  name        = "${var.vms_name}-${count.index}"
  description = var.description
  tags        = var.tags
  vm_id       = var.start_id + count.index

  node_name = var.node
  pool_id   = proxmox_virtual_environment_pool.pool.id

  bios = "ovmf"

  agent {
    enabled = var.agent_on
  }

  cpu {
    sockets      = 1
    limit        = 4
    cores        = var.resources.cpu
    architecture = var.base.arch
    type         = "x86-64-v3"
  }

  memory {
    dedicated = var.resources.memory * 1024
    floating  = 0
    hugepages = var.resources.hugepg ? "any" : null
  }

  network_device {
    bridge   = "vmbr0"
    firewall = true
  }

  initialization {
    datastore_id = var.disks.cloudinit.storage
    interface    = "scsi0"

    ip_config {
      ipv4 {
        address = "${cidrhost(var.network.cidr, count.index + var.start_id)}/${local.mask_part}"
        gateway = cidrhost(var.network.cidr, 1)
      }
    }

    dns {
      servers = var.network.dns
      domain  = "${var.vms_name}-${count.index}"
    }

    user_data_file_id = proxmox_virtual_environment_file.cloudinit_pve[count.index].id
  }

  efi_disk {
    datastore_id = "SSD"
    type = "4m"
  }

  disk {
    import_from  = proxmox_virtual_environment_download_file.cloudinit_img.id
    interface    = "virtio0"
    datastore_id = var.disks.root.storage
    iothread     = true
    size         = var.disks.root.size
    discard      = "ignore"
    replicate    = false
    ssd          = false
    backup       = false
    cache        = "none"
  }
  
  dynamic "disk" {
    for_each = var.disks.other

    content {
      interface    = "scsi${disk.key + 1}"
      size         = disk.value.size
      datastore_id = disk.value.storage
      iothread     = false
      discard      = "ignore"
      replicate    = false
      ssd          = false
      backup       = false
      cache        = "none"
    }
  }
}

resource "proxmox_virtual_environment_firewall_rules" "rules" {
  count = var.size

  node_name = proxmox_virtual_environment_vm.vm[count.index].node_name
  vm_id     = proxmox_virtual_environment_vm.vm[count.index].id

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.sc.name
    iface          = "net0"
  }
}
