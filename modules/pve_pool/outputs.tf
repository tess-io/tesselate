output "ip_addresses" {
  description = "List of IP addresses of corresponding VM from the pool"
  value       = [ for ind, vm in proxmox_virtual_environment_vm.vm: vm.agent[0].enabled ? vm.ipv4_addresses[1][0] : local.ipv4_addresses[ind] ]
}
