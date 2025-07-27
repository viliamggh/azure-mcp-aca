# Azure MCP Container Apps - GitOps Workflow

This project implements a complete GitOps workflow for deploying Azure Container Apps with blue-green deployments using Terraform and GitHub Actions.

## Architecture

- **Development Environment**: Isolated `dev` workspace with instant deployments
- **Production Environment**: Blue-green deployments with canary testing and manual promotion
- **State Management**: Terraform workspaces with Azure Blob Storage backend
- **Container Registry**: Azure Container Registry with managed identity authentication

## Developer Workflow

### 1. Inner Loop (Local Development)
```bash
# Edit code, run tests
pytest

# Test locally
docker compose up

# Commit and push to dev
git add .
git commit -m "feat: new feature"
git push origin dev
```

### 2. Deploy to Dev (Automatic)
- Push to `dev` branch triggers `deploy-dev` workflow
- Builds and pushes Docker image with commit SHA tag
- Deploys to dev environment via Terraform
- Available at: `https://dev.azure-mcp-aca.<region>.azurecontainerapps.io`

### 3. Deploy to Production (Automatic Canary)
- Push to `main` branch triggers `deploy-prod` workflow
- Builds and pushes Docker image
- Deploys as "candidate" revision with 10% traffic
- Production gets 90% traffic, candidate gets 10%
- Available at:
  - Production: `https://azure-mcp-aca.<region>.azurecontainerapps.io`
  - Candidate: `https://candidate.azure-mcp-aca.<region>.azurecontainerapps.io`

### 4. Promote to Production (Manual)
- Smoke test the candidate URL
- Manually trigger the promotion workflow
- Blue-green swap: candidate becomes production (100% traffic)
- Zero-downtime deployment

## Setup Instructions

### 1. Prerequisites
- Azure CLI installed and authenticated
- GitHub CLI installed and authenticated
- Docker installed

### 2. Bootstrap Infrastructure
```bash
# Set your GitHub token
export GH_TOKEN="<your-github-token>"

# Run the infrastructure bootstrap
./infra_base.sh
```

This creates:
- Resource Group
- User-Assigned Managed Identity
- Azure Container Registry
- Storage Account for Terraform state
- Federated credentials for GitHub OIDC
- GitHub repository variables

### 3. Initialize Terraform Workspaces

#### For Development:
```bash
cd terraform

# Initialize with backend
terraform init -backend-config=backend.conf

# Create dev workspace
terraform workspace new dev

# Deploy dev environment (first time)
terraform apply -var-file=env/dev.tfvars \
  -var="image_tag=latest" \
  -var="revision_label=dev" \
  -var="registry_identity_id=/subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<IDENTITY_NAME>"
```

#### For Production:
```bash
# Create prod workspace
terraform workspace new prod

# Deploy prod environment (first time)
terraform apply -var-file=env/prod.tfvars \
  -var="image_tag=latest" \
  -var="revision_label=prod" \
  -var="registry_identity_id=/subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<IDENTITY_NAME>"
```

### 4. GitHub Environments
Create these environments in your GitHub repository settings:
- `dev` - No protection rules
- `prod` - Require reviewers (optional)
- `prod-promote` - Require manual approval

## File Structure
```
.
├── .github/workflows/
│   ├── deploy-dev.yml      # Dev deployment workflow
│   └── deploy-prod.yml     # Prod deployment workflow
├── terraform/
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Variable definitions
│   ├── outputs.tf          # Output definitions
│   ├── backend.conf        # Backend configuration
│   └── env/
│       ├── dev.tfvars      # Dev environment variables
│       └── prod.tfvars     # Prod environment variables
├── Dockerfile              # Container definition
├── infra_base.sh          # Infrastructure bootstrap script
└── README.md              # This file
```

## Traffic Management

### Development
- 100% traffic to latest revision
- Immediate deployment of new code

### Production
- Initial: 90% prod, 10% candidate
- After promotion: 100% prod
- Old revisions remain available for instant rollback

## Environment Variables in GitHub

The bootstrap script sets these repository variables:
- `UAMI_ID` - User-assigned managed identity client ID
- `TENANT_ID` - Azure tenant ID
- `SUB_ID` - Azure subscription ID
- `ACR_NAME` - Container registry name
- `RG_NAME` - Resource group name
- `IDENTITY_NAME` - Managed identity name

## Commands Reference

### Rollback Production
```bash
# Get previous revision name
az containerapp revision list --name azure-mcp-aca-prod --resource-group azure-mcp-aca-rg

# Update traffic to previous revision
terraform apply -var-file=env/prod.tfvars \
  -var="image_tag=<previous-sha>" \
  -var="revision_label=prod" \
  -var='traffic_weights={"prod"=100}'
```

### View Logs
```bash
# Dev environment
az containerapp logs show --name azure-mcp-aca-dev --resource-group azure-mcp-aca-rg

# Prod environment
az containerapp logs show --name azure-mcp-aca-prod --resource-group azure-mcp-aca-rg
```

### Scale Manually
```bash
# Update terraform variables or use Azure CLI
az containerapp update --name azure-mcp-aca-dev --resource-group azure-mcp-aca-rg --min-replicas 1 --max-replicas 10
```

## Security Features

- **OIDC Authentication**: No stored secrets, uses federated credentials
- **Managed Identity**: Container apps authenticate to ACR using managed identity
- **Network Isolation**: Option to deploy in private subnets (update terraform variables)
- **HTTPS Only**: All traffic encrypted in transit
- **Health Checks**: Liveness and readiness probes configured

## Monitoring

- **Application Insights**: Automatic telemetry collection
- **Log Analytics**: Centralized logging
- **Metrics**: CPU, memory, and request metrics
- **Alerts**: Configure in Azure Portal for production monitoring

## Cost Optimization

- **Dev Environment**: Scales to zero when not in use
- **Prod Environment**: Minimum 1 replica for availability
- **Consumption Tier**: Pay only for actual usage
- **Shared Log Analytics**: Single workspace for both environments