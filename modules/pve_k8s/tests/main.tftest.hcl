provider "vault" {
  # Configure it with environment variables
  # VAULT_ADDR - vault http/https address
  # VAULT_TOKEN - vault auth token
}

variable "proxmox_endpoint" {
  description = "Proxmox VE endpoint URL"

  type     = string
  nullable = false
}

variable "playbooks_dir" {
  description = "The local path where playbooks locate"
  type        = string
}

variable "ssh_public_key" {
  description = "The path to the local SSH public key"
  type        = string
}

variables {
  network = {
    cidr   = "192.168.0.0/24"
    dns    = "8.8.8.8"
  }
  
  base = {
    os      = "alpine"
    arch    = "x86_64"
    version = "3.21.0"
  }

  start_id = 120
  node     = "pve"

  groups = {
    tcontrol = {
      size       = 2
      node_name  = "test-control-node"
      is_control = true
      reserved   = 2

      resources = {
        cpu    = 4
        memory = 8         
      }
    }

    tworker = {
      size      = 2
      node_name = "test-worker-node"
      reserved  = 2

      resources = {
        cpu    = 4
        memory = 8
      }
    }
  }

  kubeconfig_path = "/tmp/k8s_admin_test.conf"
}

run "setup" {
  module {
    source = "./testing/setup"
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true

  username = run.setup.creds.proxmox.username
  password = run.setup.creds.proxmox.password
}

provider "helm" {
  kubernetes = {
    config_path = "/tmp/k8s_admin_test.conf"
  }
}

run "apply" {
  command = apply

  variables {
    auth = {
      user     = "user"
      pass     = "$5$C.6CsFKu0G6.tRIc$ciI0ED17SzFKA10agSTe87SnfLQ32q9iu8sq3ivt0R9"
      ssh_keys = [ trimspace(file(var.ssh_public_key)) ]
    }

    cert = {
      ca  = run.setup.cert.ca
      key = run.setup.cert.key
    }
  }
}

run "verify" {
  variables {
    kubeconfig_path = "/tmp/k8s_admin_test.conf"
  }
  
  module {
    source = "./testing/verify"
  }

  assert {
    condition = data.http.requests["healthz"].response_body == "ok" && data.http.requests["healthz"].status_code == 200
    error_message = "The cluster is not healthy. Expected: ok, 200 . Actual: ${data.http.requests["healthz"].response_body}, ${data.http.requests["healthz"].status_code }"
  }

  assert {
    condition = data.http.requests["readyz"].response_body == "ok" && data.http.requests["readyz"].status_code == 200
    error_message = "The cluster is not ready. Expected: ok, 200. Actual: ${data.http.requests["readyz"].response_body}, ${data.http.requests["readyz"].status_code}"
  }

  assert {
    condition = data.http.requests["livez"].response_body == "ok" && data.http.requests["livez"].status_code == 200
    error_message = "The cluster is not live. Expected: ok, 200. Actual: ${data.http.requests["livez"].response_body}, ${data.http.requests["livez"].status_code}"
  }

  assert {
    condition = data.http.cilium.status_code == 200
    error_message = "The cilium CNI is not found in cluster. Expected: 200. Actual: ${data.http.cilium.status_code}"
  }
}
