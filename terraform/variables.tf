# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "azure-mcp-aca"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

# Container Configuration
variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

variable "revision_label" {
  description = "Label for the container app revision"
  type        = string
}

variable "container_cpu" {
  description = "CPU allocation for the container"
  type        = number
  default     = 0.25
}

variable "container_memory" {
  description = "Memory allocation for the container"
  type        = string
  default     = "0.5Gi"
}

variable "container_env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

# Scaling Configuration
variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "scale_concurrent_requests" {
  description = "Number of concurrent requests to trigger scaling"
  type        = number
  default     = 50
}

# Traffic Configuration for Blue-Green Deployments
variable "traffic_weights" {
  description = "Traffic weights for different revisions"
  type        = map(number)
  default = {
    latest = 100
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "azure-mcp-aca"
  }
}
