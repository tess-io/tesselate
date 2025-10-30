data "vault_kv_secret_v2" "proxmox_creds" {
  mount = "infra-secrets"
  name  = "testing/proxmox/creds"
}

locals {
  proxmox_creds = data.vault_kv_secret_v2.proxmox_creds.data
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "tls_private_key" "cert" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem       = tls_private_key.cert.private_key_pem
  validity_period_hours = 24

  allowed_uses = [
    "any_extended",
    "client_auth",
    "server_auth",
    "timestamping",
    "crl_signing",
    "ocsp_signing",
    "cert_signing",
  ]

  subject {
    common_name = "Kubernetes"
  }

  is_ca_certificate = true
}
