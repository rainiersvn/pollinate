# Inputs for ck-labs_az_observability. Grouped typed objects with optional()
# defaults; the root module passes one workspace + one insights object.

variable "location" {
  description = "Azure region for the ck-labs observability resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the ck-labs observability resources."
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

variable "workspace" {
  description = "Log Analytics workspace knobs."
  type = object({
    sku            = optional(string, "PerGB2018")
    retention_days = optional(number, 30)
    daily_quota_gb = optional(number, 1)
  })
  default = {}
}

variable "insights" {
  description = "Application Insights knobs (web type, workspace-backed)."
  type = object({
    retention_days = optional(number, 90)
    sampling       = optional(number, 100)
  })
  default = {}
}

variable "tags" {
  description = "Extra tags merged over the ck-labs defaults."
  type        = map(string)
  default     = {}
}
