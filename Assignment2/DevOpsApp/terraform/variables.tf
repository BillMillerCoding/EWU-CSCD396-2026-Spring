variable "image_name" {
  description = "Container image to deploy"
  type        = string
}

variable "acr_username" {
  description = "ACR username"
  type        = string
}

variable "acr_password" {
  description = "ACR password"
  type        = string
  sensitive   = true
}