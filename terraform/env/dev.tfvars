# Dev Environment Configuration
project_name        = "azure-mcp-aca"
environment        = "dev"
resource_group_name = "azure-mcp-aca-rg"
acr_name           = "azuremcpacaacr"

# Container Configuration
container_cpu    = 0.25
container_memory = "0.5Gi"

# Scaling Configuration
min_replicas               = 0
max_replicas              = 5
scale_concurrent_requests = 30

# Traffic Configuration (100% to latest for dev)
traffic_weights = {
  latest = 100
}

# Tags
tags = {
  Environment = "dev"
  Project     = "azure-mcp-aca"
  ManagedBy   = "terraform"
}
