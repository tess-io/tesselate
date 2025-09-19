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
    size      = number
    node_name = string

    resources = object({
      cpu    = number
      memory = number
    })
  }))
  nullable = false
}
