mock_provider "proxmox" {}

variables {
  name     = "test-pool"
  vms_name = "test-vm"
  node     = "test-node"
  start_id = 100
  size     = 1

  auth = {
    user     = "test-user"
    pass     = "$5$QtTCZ.eLYjOlkgnS$eQLgYdp3c/diYdGf/ALJ5S0AdIlv8ru02S1Qg/3aVI2"
    ssh_keys = null
  }

  disks = {
    root      = { storage = "test", size = 4, },
    cloudinit = { storage = "test" },
    other     = [],
  }

  network = {
    cidr   = "192.168.0.0/24",
    dns    = [],
    domain = "domain.test",
    acls   = [{ cidr = "192.168.0.0/24", ports = "22", policy = "accept", proto = "tcp", }],
  }
}

run "validate_tags_success" {
  command = plan

  variables {
    tags = ["simple", "multi-word", "multi_word_"]
  }
}

run "validate_tags_failed" {
  command = plan

  variables {
    tags = ["uncorrect tag fomration"]
  }

  expect_failures = [var.tags]
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

  expect_failures = [var.size]
}

run "validate_auth_success" {
  command = plan

  variables {
    auth = {
      user     = "user"
      pass     = "$5$QtTCZ.eLYjOlkgnS$eQLgYdp3c/diYdGf/ALJ5S0AdIlv8ru02S1Qg/3aVI2"
      ssh_keys = null,
    }
  }
}

run "validate_auth_failed_null" {
  command = plan

  variables {
    auth = {
      user     = "test-user"
      pass     = null,
      ssh_keys = null,
    }
  }

  expect_failures = [var.auth]
}

run "validate_auth_failed_pass" {
  command = plan

  variables {
    auth = {
      user     = "user"
      pass     = "pass"
      ssh_keys = null
    }
  }

  expect_failures = [var.auth]
}

run "validate_start_id_success" {
  command = plan

  variables {
    start_id = 100
  }
}

run "validate_start_id_failed" {
  command = plan

  variables {
    start_id = 0
  }

  expect_failures = [var.start_id]
}
