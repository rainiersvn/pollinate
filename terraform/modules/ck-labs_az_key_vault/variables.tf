# Inputs for ck-labs_az_key_vault. Grouped typed objects with optional()
# defaults; the root module passes one vault object plus secret values.

variable "location" {
  description = "Azure region for the ck-labs key vault."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the ck-labs key vault."
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

variable "vault" {
  description = "Key vault knobs (RBAC-only; no access policies)."
  type = object({
    name                          = optional(string, null)
    sku_name                      = optional(string, "standard")
    soft_delete_retention_days    = optional(number, 7)
    purge_protection_enabled      = optional(bool, false)
    public_network_access_enabled = optional(bool, true)
  })
  default = {}

  validation {
    condition     = contains(["standard", "premium"], var.vault.sku_name)
    error_message = "vault.sku_name must be \"standard\" or \"premium\"."
  }
}

variable "secrets" {
  description = "Secret name to value map (e.g. RiskShield API key). Values stay sensitive."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "tags" {
  description = "Extra tags merged over the ck-labs defaults."
  type        = map(string)
  default     = {}
}
