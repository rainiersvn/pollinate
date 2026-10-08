# Container App for the ck-labs API: own environment, own identity, MI-only
# registry pull, Key Vault secret refs (values never touch Terraform).
#
# RBAC propagation guard: AAD role assignments take effect asynchronously, so
# the app waits on time_sleep before its first image pull / secret resolve.

resource "azurerm_user_assigned_identity" "this" {
  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_container_app_environment" "this" {
  name                       = local.env_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = local.common_tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "time_sleep" "rbac_propagation" {
  create_duration = var.rbac_propagation_delay

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.key_vault_secrets_user,
  ]
}

resource "azurerm_container_app" "this" {
  name                         = local.app_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  registry {
    server   = var.registry_login_server
    identity = azurerm_user_assigned_identity.this.id
  }

  # One secret block per Key Vault ref; values resolve inside Azure only.
  dynamic "secret" {
    for_each = var.key_vault_secrets
    content {
      name                = secret.key
      identity            = azurerm_user_assigned_identity.this.id
      key_vault_secret_id = secret.value
    }
  }

  ingress {
    external_enabled = var.ingress.external_enabled
    target_port      = var.ingress.target_port
    transport        = "http"
    # No timeout knob exists on the azurerm 4.81 ingress block: the platform
    # front-end times out at ~30s, so the app total budget (RiskShield
    # TimeoutSeconds x (MaxRetries+2) = 5s x 5 = 25s) must stay under it.
    # Otherwise ingress returns 504 before the app maps its own 504.

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.scaling.min_replicas
    max_replicas = var.scaling.max_replicas

    container {
      name   = "api"
      image  = "${var.registry_login_server}/${var.image.name}:${var.image.tag}"
      cpu    = var.app.cpu
      memory = var.app.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env
        content {
          name        = env.key
          secret_name = env.value
        }
      }

      liveness_probe {
        port                    = var.ingress.target_port
        transport               = "HTTP"
        path                    = var.health.liveness_path
        interval_seconds        = 30
        timeout                 = 5
        failure_count_threshold = 3
      }

      readiness_probe {
        port                    = var.ingress.target_port
        transport               = "HTTP"
        path                    = var.health.readiness_path
        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 3
        success_count_threshold = 1
      }
    }
  }

  tags = local.common_tags

  depends_on = [time_sleep.rbac_propagation]
}
