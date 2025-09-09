variables {
  name     = "test-pool"
  vms_name = "test-vm"
  size  = 1
  disks = [
    { storage = "test-storage", size = 1 }
  ]
  network = {
    cidr = "192.168.0.0/24",
    dns  = "8.8.8.8",
    acls = [ { cidr = "192.168.0.0/24", ports = "22", policy = "allow", } ],
  }
}

run "validate_tags_success" {
  command = plan
  
  variables {
    tags = [ "simple", "multi-word", "multi_word_" ]
  }
}

run "validate_tags_failed" {
  command = plan
  
  variables {
    tags = [ "uncorrect tag fomration"]
  }

  expect_failures = [ var.tags ]
}

run "validate_size_success" {
  command = plan

  variables {
    size = 0
  }
}

run "validate_size_failed" {
  command = plan
  
  variables {
    size = -1
  }

  expect_failures = [ var.size ]
}
