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
