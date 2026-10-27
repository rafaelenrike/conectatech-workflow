variable "resource_group_name" {
  description = "Grupo de recursos creado durante el bootstrap."
  type        = string
  default     = "rg-code-to-cloud-demo"
}

variable "name_suffix" {
  description = "Sufijo alfanumérico corto y único para nombres globales, por ejemplo rafa26."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{4,10}$", var.name_suffix))
    error_message = "Use de 4 a 10 caracteres en minúscula, únicamente letras y números."
  }
}

variable "initial_image" {
  description = "Imagen pública temporal usada antes del primer despliegue de la aplicación."
  type        = string
  default     = "mcr.microsoft.com/dotnet/samples:aspnetapp"
}

variable "tags" {
  description = "Etiquetas comunes."
  type        = map(string)
  default = {
    workshop = "code-to-cloud-devsecops"
    purpose  = "demo"
  }
}
