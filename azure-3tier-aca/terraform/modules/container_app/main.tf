resource "azurerm_container_app" "main" {
  name                         = "ca-${var.name}"
  container_app_environment_id = var.container_apps_env_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  # Secrets must be defined BEFORE template
  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = var.container_image
      cpu    = var.cpu_requests
      memory = var.memory_requests

      dynamic "env" {
        # ensure an iterable; list is fine
        for_each = var.environment_variables
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }
  }


  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      allow_insecure_connections = true   # Allow HTTP for internal Application Gateway communication
      external_enabled           = true   # Temporarily external to bypass environment limit
      target_port                = var.container_port
      transport                  = "auto"
      
      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }
}