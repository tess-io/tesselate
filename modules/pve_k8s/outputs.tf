output "ansible_logs" {
  description = "Locations of the playbooks launch logs"

  value = {
    control = local.control_group_name == null ? null : {
      stderr = ansible_playbook.control[0].ansible_playbook_stderr
      stdout = ansible_playbook.control[0].ansible_playbook_stdout
    }
    workers = {
      for group in local.worker_groups: group => {
        stderr = ansible_playbook.workers[group].ansible_playbook_stderr
        stdout = ansible_playbook.workers[group].ansible_playbook_stdout
      }
    }
  }
}

output "ansible_inventory" {
  description = "A temporary ansible inventory file. Use it only for debugging purposes"

  value = {
    control = local.control_group_name == null ? null : ansible_playbook.control[0].temp_inventory_file

    workers = {
      for group in local.worker_groups:
        group => ansible_playbook.workers[group].temp_inventory_file
    }
  }
}
