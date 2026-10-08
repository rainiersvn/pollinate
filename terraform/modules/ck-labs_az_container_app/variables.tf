# Inputs for ck-labs_az_container_app. Grouped typed objects with
# optional() defaults; the root module passes plain ids (registry, vault,
# workspace) so this module never references its sibling modules.

variable "location" {
  description = "Azure region for the ck-labs container app."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the ck-labs container app."
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

variable "log_analytics_workspace_id" {
  description = "Workspace id for the Container Apps environment diagnostics."
  type        = string
}

variable "registry_login_server" {
  description = "ACR login server prefixing the API image."
  type        = string
}

variable "registry_id" {
  description = "ACR id (scope of the AcrPull assignment)."
  type        = string
}

variable "key_vault_id" {
  description = "Key vault id (scope of the Secrets User assignment)."
  type        = string
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

  validation {
    condition     = var.scaling.min_replicas >= 0 && var.scaling.max_replicas >= var.scaling.min_replicas
    error_message = "scaling requires 0 <= min_replicas <= max_replicas."
  }
}

variable "ingress" {
  description = "Ingress knobs (external HTTPS, plain HTTP to the container)."
  type = object({
    external_enabled = optional(bool, true)
    target_port      = optional(number, 8080)
  })
  default = {}
}

variable "health" {
  description = "Probe paths served by the ck-labs API."
  type = object({
    liveness_path  = optional(string, "/health/live")
    readiness_path = optional(string, "/health/ready")
  })
  default = {}
}

variable "env_vars" {
  description = "Plain environment values (no telemetry wiring; Insights connection string intentionally not passed)."
  type        = map(string)
  default     = {}
}

variable "key_vault_secrets" {
  description = "Secret-block name to versionless vault secret id (Key Vault refs, never values)."
  type        = map(string)
  default     = {}
}

variable "secret_env" {
  description = "Container env name to secret-block name for vault-backed settings."
  type        = map(string)
  default     = {}
}

variable "rbac_propagation_delay" {
  description = "Guard delay letting AAD role assignments propagate before the app pulls."
  type        = string
  default     = "60s"
}

variable "tags" {
  description = "Extra tags merged over the ck-labs defaults."
  type        = map(string)
  default     = {}
}
