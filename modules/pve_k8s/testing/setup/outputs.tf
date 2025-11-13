output "ssh" {
  description = "SSH private and public keys"
  sensitive   = true

  value = {
    private_key = tls_private_key.ssh.private_key_openssh
    public_key  = tls_private_key.ssh.public_key_openssh
  }
}

output "cert" {
  description = "A self-signed certificate used to deploy the K8S test cluster"
  sensitive   = true
  #ephemeral = true

  value = {
    ca  = tls_self_signed_cert.cert.cert_pem
    key = tls_private_key.cert.private_key_pem
  }
}

output "creds" {
  description = "Sensitive information obtained from Vault"
  #ephemeral   = true
  sensitive = true

  value = {
    proxmox = {
      username = local.proxmox_creds.username
      password = local.proxmox_creds.password
    }
  }
}
