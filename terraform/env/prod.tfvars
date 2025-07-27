# Production Environment Configuration
project_name        = "azure-mcp-aca"
environment        = "prod"
resource_group_name = "azure-mcp-aca-rg"
acr_name           = "azuremcpacaacr"

# Container Configuration
container_cpu    = 0.5
container_memory = "1Gi"

# Scaling Configuration
min_replicas               = 1
max_replicas              = 10
scale_concurrent_requests = 100

# Traffic Configuration (Blue-Green setup for prod)
traffic_weights = {
  prod = 90
  candidate = 10
}

# Tags
tags = {
  Environment = "prod"
  Project     = "azure-mcp-aca"
  ManagedBy   = "terraform"
}
