# Root inputs. Thin pass-throughs: naming + tags + lock live here,
# everything else forwards to the child module that owns it.

variable "location" {
  description = "Azure region for the ck-labs resource group and modules."
  type        = string
  default     = "southafricanorth"
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

variable "project" {
  description = "Project slug for the Project tag."
  type        = string
  default     = "ck-labs"
}

variable "tags" {
  description = "Extra tags merged over the Environment/Project defaults."
  type        = map(string)
  default     = {}
}

variable "lock_type" {
  description = "Resource-group lock level; empty string disables the lock (dev)."
  type        = string
  default     = ""

  validation {
    condition     = contains(["", "CanNotDelete", "ReadOnly"], var.lock_type)
    error_message = "lock_type must be \"\", \"CanNotDelete\" or \"ReadOnly\"."
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
}

variable "secrets" {
  description = "Secret name to value map (e.g. RiskShield API key). Values stay sensitive; prefer -var / TF_VAR_ over tfvars."
  type        = map(string)
  default     = {}
  sensitive   = true
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

variable "image" {
  description = "API image coordinates (registry server is prepended)."
  type = object({
    name = optional(string, "finsure-risk-scoring")
    tag  = optional(string, "latest")
  })
  default = {}
}

variable "app" {
  description = "Container sizing for the ck-labs API."
  type = object({
    cpu    = optional(number, 0.25)
    memory = optional(string, "0.5Gi")
  })
  default = {}
}

variable "scaling" {
  description = "Replica bounds for the ck-labs API."
  type = object({
    min_replicas = optional(number, 1)
    max_replicas = optional(number, 3)
  })
  default = {}
}

variable "env_vars" {
  description = "Plain environment values (no telemetry wiring; Insights connection string intentionally not passed)."
  type        = map(string)
  default     = {}
}

variable "secret_env" {
  description = "Container env name to secret-block name for vault-backed settings."
  type        = map(string)
  default     = {}
}
