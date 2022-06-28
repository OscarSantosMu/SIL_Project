variable "location" {
  description = ""
  type        = string
}

variable "uniquer" {
  description = ""
  type        = string
  default     = null
}

variable "resources_prefix" {
  description = ""
  type        = string
  default     = null
}

# Input variable: Name of Resource Group
variable "resource_group_name" {
  default = "tfstorageaccounteduenvs-rg"
}

# Input variable: Name of Storage Account
variable "storage_account_name" {
  description = "The name of the storage account. Must be globally unique, length between 3 and 24 characters and contain numbers and lowercase letters only."
  default     = "tfstorageaccounteduenvs"
}

# Input variable: Name of Storage container
variable "container_name" {
  description = "The name of the Blob Storage container."
  default     = "terraform-state-container"
}