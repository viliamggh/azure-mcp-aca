terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    # Configuration will be provided via backend config file or CLI
  }
}

provider "azurerm" {
  features {}
}

# Data sources for existing resources
data "azurerm_client_config" "current" {}

data "azurerm_user_assigned_identity" "uami" {
  name                = var.uami_name
  resource_group_name = var.resource_group_name
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.project_name}-env-${var.environment}"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = var.tags
}

resource "azurerm_role_assignment" "container_app_acrpull" {
  scope                = data.azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = data.azurerm_user_assigned_identity.uami.principal_id
}


# Container App
resource "azurerm_container_app" "main" {
  depends_on = [ azurerm_role_assignment.container_app_acrpull ]
  name                         = "${var.project_name}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = "Multiple"

  # Registry configuration for ACR
  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.uami.id]
  }
  registry {
    server   = data.azurerm_container_registry.main.login_server
    identity = data.azurerm_user_assigned_identity.uami.id
  }

  template {
    # Dynamic revision suffix based on image tag
    revision_suffix = var.revision_label

    container {
      name   = "mcp-server"
      image  = "${data.azurerm_container_registry.main.login_server}/mcp:${var.image_tag}"
      cpu    = var.container_cpu
      memory = var.container_memory

      # Health checks
      liveness_probe {
        transport               = "HTTP"
        port                   = 8000
        path                   = "/mcp/resource/health"
        initial_delay          = 10
        interval_seconds       = 30
        timeout                = 5
        failure_count_threshold = 3
      }

      readiness_probe {
        transport                = "HTTP"
        port                    = 8000
        path                    = "/mcp/resource/health"
        initial_delay           = 5
        interval_seconds        = 10
        timeout                 = 3
        failure_count_threshold = 3
        success_count_threshold = 1
      }

      # Environment variables
      dynamic "env" {
        for_each = var.container_env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # HTTP scaling rules
    http_scale_rule {
      name                = "http-requests"
      concurrent_requests = var.scale_concurrent_requests
    }
  }

  # Ingress configuration
  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http"

    # Dynamic traffic weights for blue-green deployments
    dynamic "traffic_weight" {
      for_each = var.traffic_weights
      content {
        label      = traffic_weight.key
        percentage = traffic_weight.value
        # For the latest revision, use latest_revision = true
        latest_revision = traffic_weight.key == "latest" ? true : false
        # For specific revisions, use revision_suffix
        revision_suffix = traffic_weight.key != "latest" ? traffic_weight.key : null
      }
    }
  }

  tags = var.tags
}
