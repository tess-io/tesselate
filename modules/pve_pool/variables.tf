variable "name" {
  description = "VMs pool name"
  type      = string
  nullable  = false
}

variable "vms_name" {
  description = "VMs base name"
  type        = string
  nullable    = false
}

variable "description" {
  description = "VMs pool description"
  type        = string
  default     = ""
}

variable "tags" {
  description = "VMs tags"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for tag in var.tags: can(regex("^[a-zA-Z0-9-_]+$", tag))])
    error_message = "The tag must contain only alphanumeric and '-', '_' characters"
  }
}

variable "agent_on" {
  description = "Whether to enable QEMU agent on VMs"
  type        = bool
  default     = false  
}

variable "node" {
  description = "The name of the node that was used to create the VMs"
  type        = string
  default     = null
}

variable "size" {
  description = "The size of the pool - count of VMs in pool"
  type        = number
  nullable    = false

  validation {
    condition     = var.size >= 0
    error_message = "Count of VMs must be greater than 0"
  }
}

variable "resources" {
  description = "Allocated to VMs physical resources"
  type        = object({
    cpu    = number,
    memory = number, 
    hugepg = bool,
  })
  default = { cpu = 4, memory = 4, hugepg = false }
}

variable "base" {
  description = "Information about base cloud image for VMs, which will be downloaded from corresponding URL"
  type        = object({
    os      = string,
    version = string,
    bios    = string,
    arch    = string,
  })
  default = { os = "ubuntu", version = "24.04-LTS", bios = "uefi", arch = "x86_64" }
}

variable "network" {
  description = "Network configuration information"
  type        = object({
    cidr = string,
    dns  = string,
    acls = list(object({
      cidr   = string,
      ports  = string,
      policy = string,
    }))
  })
  nullable = false
}

variable "disks" {
  description = "Disks configuration information"
  type        = list(object({
    storage = string,
    size    = number,
  }))
  nullable  = false
}

