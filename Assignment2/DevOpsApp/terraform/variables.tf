variable "image_name" {
  description = "Container image to deploy"
  type        = string
}

variable "acr_name" {
  description = "Existing Azure Container Registry name"
  type        = string
  default     = "a2containerregistrybillm"
}

variable "acr_resource_group_name" {
  description = "Resource group containing the existing Azure Container Registry"
  type        = string
  default     = "devops-rg"
}