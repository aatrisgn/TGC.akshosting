variable "resource_group_name" {
  type = string
}
variable "environment_type_name" {
  type = string
}
variable "tenant_id" {
  description = "ID of the Entra tenant for service prinipal storage"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "The variable value must be a valid GUID in the format 00000000-0000-0000-0000-000000000000."
  }
}

# variable "aks_host_name" {
#   type = string
# }