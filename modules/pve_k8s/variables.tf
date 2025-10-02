variable "node" {
  description = "The name of the node that was used to create the VMs"
  type        = string
  default     = null
}

variable "start_id" {
  description = "First VM in pool identifier"
  type        = number
  nullable    = false

  validation {
    condition     = var.start_id > 0
    error_message = "VM id must be greater than 0"
  }
}

variable "auth" {
  description = "VMs auth credentials"
  type = object({
    user     = string,
    pass     = string,
    ssh_keys = list(string),
  })
  nullable = false

  validation {
    condition     = var.auth.pass != null || var.auth.ssh_keys != null
    error_message = "One of the 'pass' or 'ssh_keys' must be specified"
  }

  validation {
    condition     = var.auth.pass == null || (startswith(var.auth.pass, "$5$") && length(var.auth.pass) == 63)
    error_message = "Use hash ('openssl passwd -5' command) instead of plain text"
  }
}

variable "base" {
  description = "Information about base cloud image for VMs, which will be downloaded from corresponding URL"
  type = object({
    os      = string
    version = string
    arch    = string
  })
  default = { os = "alpine", version = "3.21.0", arch = "x86_64" }
}

variable "network" {
  description = "Basic claster network settings"
  type = object({
    cidr   = string
    dns    = string
    domain = string
  })
  default = { cidr = "172.16.0.0/24", dns = "8.8.8.8", domain = "cluster.local" }

  validation {
    condition     = var.network.cidr != null
    error_message = "Format must be such as '172.16.0.0/24'"
  }

  validation {
    condition     = var.network.dns != null
    error_message = "Must have valid DNS format or IP address"
  }

  validation {
    condition     = var.network.domain != null
    error_message = "Must have valid domain name"
  }
}

variable "groups" {
  description = "Node group settings"
  type = map(object({
    size       = number
    node_name  = string
    is_control = optional(bool, false)
    reserved   = optional(number, 5)

    resources = object({
      cpu    = number
      memory = number
    })
  }))
  nullable = false
}

variable "cert" {
  description = "K8S CA certificate"
  type = object({
    ca = string,
    key = string,
  })
  nullable = false
}
