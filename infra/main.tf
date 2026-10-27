data "azurerm_resource_group" "demo" {
  name = var.resource_group_name
}

resource "azurerm_log_analytics_workspace" "demo" {
  name                = "log-ctc-${var.name_suffix}"
  location            = data.azurerm_resource_group.demo.location
  resource_group_name = data.azurerm_resource_group.demo.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_container_registry" "demo" {
  name                          = "acrctc${var.name_suffix}"
  resource_group_name           = data.azurerm_resource_group.demo.name
  location                      = data.azurerm_resource_group.demo.location
  sku                           = "Basic"
  admin_enabled                 = false
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_user_assigned_identity" "container_app" {
  name                = "id-ctc-${var.name_suffix}"
  resource_group_name = data.azurerm_resource_group.demo.name
  location            = data.azurerm_resource_group.demo.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.demo.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

resource "azurerm_container_app_environment" "demo" {
  name                       = "cae-ctc-${var.name_suffix}"
  location                   = data.azurerm_resource_group.demo.location
  resource_group_name        = data.azurerm_resource_group.demo.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo.id
  tags                       = var.tags
}

resource "azurerm_container_app" "demo" {
  name                         = "ca-code-to-cloud-${var.name_suffix}"
  container_app_environment_id = azurerm_container_app_environment.demo.id
  resource_group_name          = data.azurerm_resource_group.demo.name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  registry {
    server   = azurerm_container_registry.demo.login_server
    identity = azurerm_user_assigned_identity.container_app.id
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "web"
      image  = var.initial_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "APP_VERSION"
        value = "bootstrap"
      }

      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/"
      }
    }
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}
