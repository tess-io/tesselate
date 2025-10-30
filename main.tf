provider "vault" {
  # configure it using environment variables
  # VAULT_ADDR - target Vault address
  # VAULT_TOKEN - auth token

  max_lease_ttl_seconds = 7200
}
