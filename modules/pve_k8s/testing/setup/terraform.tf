terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.2.0"
    }
  }
}
