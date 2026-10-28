output "container_app_name" {
  description = "Nombre de la aplicación en Azure Container Apps."
  value       = azurerm_container_app.demo.name
}

output "application_url" {
  description = "URL HTTPS pública."
  value       = "https://${azurerm_container_app.demo.latest_revision_fqdn}"
}

output "acr_name" {
  description = "Nombre del Azure Container Registry."
  value       = azurerm_container_registry.demo.name
}

output "acr_login_server" {
  description = "Servidor del registro."
  value       = azurerm_container_registry.demo.login_server
}
