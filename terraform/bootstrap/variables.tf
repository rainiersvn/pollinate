variable "location" {
  description = "Azure region for the ck-labs Terraform state storage."
  type        = string
  default     = "southafricanorth"
}

variable "project" {
  description = "Project slug used in ck-labs resource names (RG, containers)."
  type        = string
  default     = "ck-labs"
}

variable "storage_suffix" {
  description = "Short unique suffix for the storage account name, which must be globally unique (lowercase alphanumeric, 2-8 chars), e.g. \"fin01\"."
  type        = string
  default     = "fin01"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.storage_suffix))
    error_message = "storage_suffix must be 2-8 lowercase alphanumeric characters."
  }
}
