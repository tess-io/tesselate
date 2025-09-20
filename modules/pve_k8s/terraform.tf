terraform {
  required_version = ">= 1.13.0"
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = ">= 1.3.0"
    }
  }
}
