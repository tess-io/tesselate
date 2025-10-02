output "about" {
  description = "List with information about the corresponding VMs from the pool"
  value       = [
    for ind, vm in proxmox_virtual_environment_vm.vm:
      {
        name       = "${var.vms_name}-${ind}"
        ip_address = vm.agent[0].enabled && var.use_agent ? vm.ipv4_addresses[1][0] : local.ipv4_addresses[ind]
      }
  ]
}
