# Inputs for ck-labs_az_container_registry. Grouped typed objects with
# optional() defaults; the root module passes one registry object.

variable "location" {
  description = "Azure region for the ck-labs container registry."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the ck-labs container registry."
  type        = string
}

variable "name_prefix" {
  description = "ck-labs name prefix, e.g. \"ck-labs\"."
  type        = string
  default     = "ck-labs"
}

variable "environment" {
  description = "Environment suffix used in resource names."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "registry" {
  description = "Container registry knobs (MI pull; admin account stays off)."
  type = object({
    name                          = optional(string, null)
    sku                           = optional(string, "Basic")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, true)
  })
  default = {}

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.registry.sku)
    error_message = "registry.sku must be \"Basic\", \"Standard\" or \"Premium\"."
  }
}

variable "tags" {
  description = "Extra tags merged over the ck-labs defaults."
  type        = map(string)
  default     = {}
}
