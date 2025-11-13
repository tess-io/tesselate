output "ansible_logs" {
  description = "Locations of the playbooks launch logs"

  value = {
    control_init = local.control_group_name == null ? null : {
      stderr = ansible_playbook.control_init.ansible_playbook_stderr
      stdout = ansible_playbook.control_init.ansible_playbook_stdout
    }
    control_join = local.control_group_name == null ? null : [
      for control_join in ansible_playbook.control_join : {
        stderr = control_join.ansible_playbook_stderr
        stdout = control_join.ansible_playbook_stdout
      }
    ]
    workers = {
      for addr, info in local.worker_groups_machines : info.group => {
        stderr = ansible_playbook.workers[addr].ansible_playbook_stderr
        stdout = ansible_playbook.workers[addr].ansible_playbook_stdout
      }...
    }
    labels = {
      for addr, info in local.worker_groups_machines : info.group => {
        stderr = ansible_playbook.labels[addr].ansible_playbook_stderr
        stdout = ansible_playbook.labels[addr].ansible_playbook_stdout
      }...
    }
  }
}
