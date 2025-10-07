ephemeral "vault_kv_secret_v2" "proxmox_creds" {
  mount = "infra-secrets"
  name = "proxmox/creds"
}

locals {
  vault_proxmox = ephemeral.vault_kv_secret_v2.proxmox_creds.data
  proxmox_user  = local.vault_proxmox.username
  proxmox_pass  = local.vault_proxmox.password
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true

  username = local.proxmox_user
  password = local.proxmox_pass
}

provider "helm" {
  kubernetes = {
    config_path = "/tmp/k8s_admin.conf"
  }
}

module "pve_k8s" {
  source = "./modules/pve_k8s"

  network = {
    cidr   = "192.168.0.0/24"
    dns    = "8.8.8.8"
    domain = "cluster.local"
  }

  kubeconfig_path = "/tmp/k8s_admin.conf"

  start_id = 100
  node     = "pve"

  auth = {
    user = "user"
    pass = "$5$C.6CsFKu0G6.tRIc$ciI0ED17SzFKA10agSTe87SnfLQ32q9iu8sq3ivt0R9"
    ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK0yO9RABzbP4OhuNYjjAo+xtwyVUHsg9sbIQxhYIFMp space@space"
    ]
  }

  groups = {
    control = {
      size       = 2
      node_name  = "control-node"
      is_control = true
      reserved   = 2

      resources = {
        cpu    = 4
        memory = 8         
      }
    }
    worker = {
      size      = 2
      node_name = "worker-node"
      reserved  = 2

      resources = {
        cpu    = 4
        memory = 8
      }
    }
  }

  cert = {
    ca = <<-EOF
      -----BEGIN CERTIFICATE-----
      MIIDBTCCAe2gAwIBAgIIHmRaQvcEWNswDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
      AxMKa3ViZXJuZXRlczAeFw0yNTA5MjgwMjI5MDJaFw0zNTA5MjYwMjM0MDJaMBUx
      EzARBgNVBAMTCmt1YmVybmV0ZXMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
      AoIBAQDxaTMFw6uUpSoWKCuDsjDOALYpXZLfu3Gty0IPugfP+Y7l8Itdam1iS5qw
      Ft/S6Awe+1+EYp/mm0IDv++Vs5KoCxEJ8WCW/oEyQqbrVCCvpVxG7tLAeUmDdKNh
      bFY+ygTlJbRTSyCP30NjDP+k1JBL8YBsC3CBFC8yWfeR9IuQq1ZrxZ/3sjqh+9Nr
      WZVasqoNjikjYO0C9NWcSTWgM0/+0TWWFrimmnH4/u/Npkzj46i+u5BoRMZPRi+h
      W2y130JXgUNzGND7bEfquUyG/wAJ89TW600C91Hpu2Amjht5Xl2Ebd0VPQOH/JwU
      26zpgeL/mwogqFb/V+lz0nuBwbUjAgMBAAGjWTBXMA4GA1UdDwEB/wQEAwICpDAP
      BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSk4l0pKvYjkt9Szh7jXTRr0quSvzAV
      BgNVHREEDjAMggprdWJlcm5ldGVzMA0GCSqGSIb3DQEBCwUAA4IBAQAWq3viQFiq
      uo2niIZXETSggLNfk6TiNxA0M4sYfoIVIq90oneXReAdPPDDixLTHyAIYhTV5YvV
      zexgzm4jFk6VgG1BVz3iAf6nfzzVUWD8oIi2Vbn5FskvNABVudr0UO+8zGf5cDGP
      /Tik6HId6S2CFhq8k8WP8m9/tCxSi+kVjrFuCvYqZKfxqR1dxOCpBRY0WMW2tB9i
      zv6eXkGBL4UMNGQE3RldBHgj8Kx/IEgx5x14hDZEbzOMZbLLg5CV4iPOG9b7WOkA
      K1sGlXg0LMSLfwdzcJGSv5kw5LnmcpvuC1b1ecj/l0ZpzBDXJJN3T+hxJWqYihn2
      XIf3AXokOfHa
      -----END CERTIFICATE-----
    EOF

    key = <<-EOF
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEA8WkzBcOrlKUqFigrg7IwzgC2KV2S37txrctCD7oHz/mO5fCL
      XWptYkuasBbf0ugMHvtfhGKf5ptCA7/vlbOSqAsRCfFglv6BMkKm61Qgr6VcRu7S
      wHlJg3SjYWxWPsoE5SW0U0sgj99DYwz/pNSQS/GAbAtwgRQvMln3kfSLkKtWa8Wf
      97I6ofvTa1mVWrKqDY4pI2DtAvTVnEk1oDNP/tE1lha4pppx+P7vzaZM4+OovruQ
      aETGT0YvoVtstd9CV4FDcxjQ+2xH6rlMhv8ACfPU1utNAvdR6btgJo4beV5dhG3d
      FT0Dh/ycFNus6YHi/5sKIKhW/1fpc9J7gcG1IwIDAQABAoIBAHfcLowPIbK06peD
      rE8/+sFdUxRotFLHQ2Lxx0P9roFRO+TosJlaDSM/vHbvdIPH2LTNRBh7yz55Gaa4
      9mCSfx9WF0ijgryVclodA7lV1MDAzncdfqA32AsfrzrgylV0gkevl7+/TlSAmnmk
      a41QSLCcIJIEgABmoCRUzPm3vE+/+1Nt+8guNonyrWzKCEYjUa+nRiKcyAhGVk5j
      jA70AGRasQYSWUIRGe7DxJbkSNUz7ZG05fJUtZ4kiPZ3A5zrdDV/+jLLh/X4zfom
      k9YuDLGn/wgypjUVg6Oed8POeMgYhPuzOVdQU6O8Lf+cbcVqOE+aeHyL/PSEmoPY
      iPLdY8kCgYEA9sWj0A/VBkKPlWYpQ9x/GGF/PFaJPQoCldCpFIVSTf7RSvTM2RXu
      pZR83kwfDelpIFzLuDDsENUHNI0YwnAlmd9yyRhlXMbQfQsV2RfphXjW1bdc09c4
      vVOV/qGOap371vxvMdzGOtUno1kh6oNQH/PcldshA6/q6Q8C76olqecCgYEA+nA8
      xbdOV1ep7aJwvJ2CZQxHJc8P0x21R44ORUKP4ixZF2niARPLq2nGFn0fniG9QDOH
      4uwKq/eGz2ASV6oRCoudGBtiuEFZDZMPVnnCzuqbunpbj0XRyYCMh0oFtHCo/G58
      nniUJ1YFSbUC5Hl4Q7pRNqdBNt+JtbBCbckJS2UCgYAQyEYouzrojxRGu8jopZE7
      Lj5B8zyoGwsr9yHYlGyRg1fmehmIVfaB6kRHtfOStaIBom30W9diGarAxyu85XWZ
      LloXFQKnuZmqN1vIBNlLy3kI1cyJV6SzM4EK7R/LXm0nJMnHIVWV4LMuZ7xnv4Bu
      e94vjtSC9K7MJMo1VGP1VwKBgQCIWFK90e503uVE2wtFpPs4yFZz3ydeaO4o5s4e
      Jv7uw/Y9KQhCTeS0jgGqfLSaAwRlz6hLgvbMaRacEFHsKEre0uPUHBTC+9Df8xCG
      pAPLYy8ldzgh6IEuky3u+f3hHvThecWfAUano819M28/tGIlfWp5ttVqaokuwado
      3eqRgQKBgDFLUYilaZj4m/6NgJc+g9WdlWyB17W/XTe5FI1d+0N6zHqSZJJetCZs
      P6leR7r0chZA0FMn4nPtW3qw8tqqSXvYANwGexGT1ztsZLxZCmbii0IMb7VzzqIr
      zdL03bRon4nuJ+xDoVHDscahnaOG+zG6uYH/KpY/cAjqCUSXWt0J
      -----END RSA PRIVATE KEY-----
    EOF
  }
}

output "ansible_logs" {
  description = "Location of the ansible playbook launch logs"

  value = module.pve_k8s.ansible_logs
}
