output "ansible_logs" {
  description = "Locations of the playbooks launch logs"

  value = {
    control = local.control_group_name == null ? null : [
      for ind in range(length(local.control_group_machines)): {
        stderr = ansible_playbook.control[ind].ansible_playbook_stderr
        stdout = ansible_playbook.control[ind].ansible_playbook_stdout
      }
    ]
    workers = {
      for addr, info in local.worker_groups_machines: info.group => {
        stderr = ansible_playbook.workers[addr].ansible_playbook_stderr
        stdout = ansible_playbook.workers[addr].ansible_playbook_stdout
      }...
    }
    labels = {
      for addr, info in local.worker_groups_machines: info.group => {
        stderr = ansible_playbook.labels[addr].ansible_playbook_stderr
        stdout = ansible_playbook.labels[addr].ansible_playbook_stdout
      }...
    }
  }
}
