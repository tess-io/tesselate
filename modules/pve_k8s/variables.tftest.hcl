mock_provider "proxmox" { }

variables {
  groups   = { }
  start_id = 100

  auth = {
    user = "test-user"
    pass = "$5$FLs86nDTeGMWRQJj$2L9rGoH2CEMvZfLSvoLa08UMGd8Lw09KXdgXXqEcyOC"

    ssh_keys = null
  }
}

run "validate_network_success" {
  command = plan

  variables {
    network = { cidr = "192.168.0.1/24", dns = "dns.google.com", domain = "cluster.local", }
  }
}

run "validate_network_cidr_failed" {
  command = plan

  variables {
    network = { cidr = null, dns = "dns.google.com", domain = "cluster.local", }
  }

  expect_failures = [ var.network ]
}

run "validate_network_dns_failed" {
  command = plan

  variables {
    network = { cidr = "192.168.0.1/24" , dns = null, domain = "cluster.local", }
  }

  expect_failures = [ var.network ]
}

run "validate_network_domain_failed" {
  command = plan

  variables {
    network = { cidr = "192.168.0.1/24", dns = "dns.google.com", domain = null, }
  }

  expect_failures = [ var.network ]
}
