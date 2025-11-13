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
    domain = optional(string, "cluster.local")
  })
  default = { cidr = "172.16.0.0/24", dns = "8.8.8.8", }

  validation {
    condition     = var.network.cidr != null
    error_message = "Format must be such as '172.16.0.0/24'"
  }

  validation {
    condition     = var.network.dns != null
    error_message = "Must have valid DNS format or IP address"
  }

  validation {
    condition     = var.network.domain != null && length(var.network.domain) > 0
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

  validation {
    condition     = anytrue([for name, group in var.groups : group.is_control])
    error_message = "One of the group must be control"
  }
}

variable "cert" {
  description = "K8S CA certificate"
  type = object({
    ca  = string,
    key = string,
  })
  nullable = false

  validation {
    condition     = var.cert.ca != null
    error_message = "The certificate has an incorrect format"
  }

  validation {
    condition     = var.cert.key != null
    error_message = "The certificate's private key has an incorrect format"
  }
}

variable "kubeconfig_path" {
  description = "The local path where the kubeconfig file will be uploaded"
  type        = string
  default     = "/tmp/kubeconfig"

  validation {
    condition     = var.kubeconfig_path != null
    error_message = "${var.kubeconfig_path}: Permission denied"
  }
}

variable "playbooks_dir" {
  description = "The local path where playbooks locate. For testing purposes only"
  type        = string
  default     = null
}
