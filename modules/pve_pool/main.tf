locals {
  helpers = {
    alpine = {
      mm_version = "v${split(".", var.base.version)[0]}.${split(".", var.base.version)[1]}"
    }
    # ubuntu = {
    #   arch_replace = {
    #     x86_64  = "amd64",
    #     aarch64 = "arm64",
    #   }
    # }
  }

  urls = {
    alpine = "https://dl-cdn.alpinelinux.org/alpine/${local.helpers.alpine.mm_version}/releases/cloud/generic_alpine-${var.base.version}-x86_64-uefi-cloudinit-r0.qcow2"
    # ubuntu = "https://cloud-images.ubuntu.com/${var.base.version}/current/${var.base.version}-server-cloudimg-${local.helpers.ubuntu.arch_replace[var.base.arch]}.img"
  }
}

resource "proxmox_virtual_environment_download_file" "cloudinit_img" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node

  url       = local.urls[var.base.os]
  file_name = "${var.base.os}-v${var.base.version}-${var.base.arch}.qcow2"
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

  bios = "ovmf"

  agent {
    enabled = false
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

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = var.disks.cloudinit.storage
    interface    = "scsi0"

    user_account {
      username = "user"
      password = "user"
    }

    ip_config {
      ipv4 {
        address = "192.168.0.237/24"
        gateway = "192.168.0.1"
      }
    }

    dns {
      domain  = "${var.vms_name}-${count.index}"
      servers = [ var.network.dns, ]
    }
  }

  disk {
    import_from = proxmox_virtual_environment_download_file.cloudinit_img.id
    interface   = "virtio0"
    size        = var.disks.root.size
    discard     = "on"
    iothread    = true

    datastore_id = var.disks.root.storage
  }

  efi_disk {
    datastore_id = "SSD"
    type = "4m"
  }
  
  # dynamic "disk" {
  #   for_each = { for i, disk in var.disks.other: i => disk }

  #   content {
  #     interface    = "scsi${disk.key}"
  #     size         = disk.value.size
  #     datastore_id = disk.value.storage
  #   }
  # }
}

