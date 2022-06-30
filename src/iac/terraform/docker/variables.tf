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

variable "container_name" {
  description = "Value of the name for the Docker container"
  type        = string
  default     = "ExampleNginxContainer"
}
