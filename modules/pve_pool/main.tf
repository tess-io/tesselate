locals {
  helpers = {
    alpine = {
      mm_version = "v${split(".", var.base.version)[0]}.${split(".", var.base.version)[1]}"
    }
  }

  urls = {
    alpine = "https://dl-cdn.alpinelinux.org/alpine/${local.helpers.alpine.mm_version}/releases/cloud/generic_alpine-${var.base.version}-x86_64-${var.base.bios}-cloudinit-r0.qcow2"
  }

  sizes = {
    alpine = 8
  }
}

resource "proxmox_virtual_environment_download_file" "cloudinit_img" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node

  url = local.urls[var.base.os]
}

resource "proxmox_virtual_environment_pool" "vms_pool" {
  comment = var.description
  pool_id = var.name
}

resource "proxmox_virtual_environment_vm" "vm" {
  count = var.size

  name        = "${var.vms_name}-${count.index}"
  description = var.description
  tags        = var.tags

  node_name = var.node
  pool_id   = proxmox_virtual_environment_pool.vms_pool.id

  agent {
    enabled = var.agent_on
  }

  cpu {
    sockets      = 1
    limit        = 4
    cores        = var.resources.cpu
    architecture = var.base.arch
  }

  memory {
    dedicated = var.resources.memory * 1024
    floating  = 0
    hugepages = var.resources.hugepg ? "any" : null
  }

  disk {
    import_from = proxmox_virtual_environment_download_file.cloudinit_img.id
    interface   = "virtio0"
    size        = local.sizes[var.base.os]
    discard     = "on"
    iothread    = true

    datastore_id = "SSD"
  }

  dynamic "disk" {
    for_each = { for i, disk in var.disks: i => disk }

    content {
      interface    = "scsi${disk.key}"
      size         = disk.value.size
      datastore_id = disk.value.storage
    }
  }
}

