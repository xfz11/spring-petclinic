# Azure Container Apps Deployment Guide

This guide explains how to deploy the Spring PetClinic application to Azure Container Apps using the provided infrastructure and deployment scripts.

## Overview

The deployment setup includes:
- **Dockerfile**: Multi-stage Docker build for the Spring Boot application
- **Bicep templates**: Infrastructure as Code (IaC) for Azure resources
- **Deployment script**: Shell script for manual deployment
- **GitHub Actions workflow**: Automated CI/CD pipeline

## Architecture

The deployment creates the following Azure resources:

1. **Azure Container Registry (ACR)**: Stores the Docker images
2. **Log Analytics Workspace**: Collects logs and metrics
3. **Container Apps Environment**: Hosts the container apps
4. **Container App**: Runs the Spring PetClinic application

## Prerequisites

### For Local Deployment

1. **Azure CLI**: Install from [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Docker**: Install from [here](https://docs.docker.com/get-docker/)
3. **Azure Subscription**: You need an active Azure subscription
4. **Permissions**: Contributor access to the subscription or resource group

### For GitHub Actions Deployment

1. **Azure Service Principal**: With Contributor access to your subscription
2. **GitHub Secrets**: Configure the following secrets in your repository:
   - `AZURE_CLIENT_ID`: Service Principal Application (client) ID
   - `AZURE_TENANT_ID`: Azure Active Directory Tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Azure Subscription ID
   - `AZURE_RESOURCE_GROUP`: Name of the Azure resource group

## Manual Deployment

### Step 1: Login to Azure

```bash
az login
```

### Step 2: Set Your Subscription (if you have multiple)

```bash
az account set --subscription "<your-subscription-id>"
```

### Step 3: Run the Deployment Script

```bash
./deploy.sh -g <resource-group-name> -l <location> -n <app-name> -e <environment>
```

**Parameters:**
- `-g, --resource-group`: Azure resource group name (required)
- `-l, --location`: Azure location (default: eastus)
- `-n, --app-name`: Application name (default: petclinic)
- `-e, --environment`: Environment name (default: dev)

**Example:**

```bash
./deploy.sh -g petclinic-rg -l eastus -n petclinic -e prod
```

The script will:
1. Create the resource group if it doesn't exist
2. Deploy the infrastructure (ACR, Log Analytics, Container Apps Environment)
3. Build the Docker image
4. Push the image to Azure Container Registry
5. Deploy the Container App with the new image

### Step 4: Access Your Application

After deployment completes, the script will output the application URL. You can access your application at:

```
https://<your-app>.<region>.azurecontainerapps.io
```

## GitHub Actions CI/CD Pipeline

### Setup

1. **Create a Service Principal**:

```bash
az ad sp create-for-rbac \
  --name "petclinic-github-actions" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group-name> \
  --json-auth
```

2. **Configure GitHub Secrets**:

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

- `AZURE_CLIENT_ID`: From the service principal output
- `AZURE_TENANT_ID`: From the service principal output
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
- `AZURE_RESOURCE_GROUP`: Your resource group name

3. **Enable Federated Credentials** (Recommended for passwordless authentication):

```bash
az ad app federated-credential create \
  --id <application-id> \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<your-org>/<your-repo>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Triggering Deployments

The GitHub Actions workflow can be triggered in two ways:

1. **Automatic**: Push to the `main` branch
2. **Manual**: Go to Actions → Deploy to Azure Container Apps → Run workflow

## Docker Build

### Local Docker Build

You can also build and run the Docker image locally for testing:

```bash
# Build the image
docker build -t petclinic:latest .

# Run the container
docker run -p 8080:8080 petclinic:latest
```

Access the application at http://localhost:8080

### Multi-stage Build

The Dockerfile uses a multi-stage build:
1. **Build stage**: Uses Maven to compile and package the application
2. **Runtime stage**: Uses a smaller JRE image to run the application

This approach minimizes the final image size and improves security.

## Infrastructure Details

### Bicep Templates

The `infra/main.bicep` file defines:

- **Log Analytics Workspace**: 30-day retention, PerGB2018 pricing tier
- **Container Registry**: Basic SKU with admin user enabled
- **Container Apps Environment**: Linked to Log Analytics
- **Container App**: 
  - CPU: 0.5 cores
  - Memory: 1Gi
  - Ingress: External on port 8080
  - Health checks: Liveness and readiness probes
  - Auto-scaling: 1-3 replicas based on HTTP requests

### Parameters

You can customize the deployment by modifying `infra/main.parameters.json` or passing parameters directly:

```bash
az deployment group create \
  --resource-group <rg-name> \
  --template-file ./infra/main.bicep \
  --parameters @./infra/main.parameters.json \
  --parameters minReplicas=2 maxReplicas=5
```

## Monitoring and Troubleshooting

### View Logs

```bash
# Get Container App name
CONTAINER_APP_NAME=$(az containerapp list \
  --resource-group <rg-name> \
  --query "[0].name" -o tsv)

# Stream logs
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group <rg-name> \
  --follow
```

### Check Application Health

```bash
# Get the application URL
APP_URL=$(az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group <rg-name> \
  --query properties.configuration.ingress.fqdn -o tsv)

# Check health endpoint
curl https://$APP_URL/actuator/health
```

### View in Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your resource group
3. Select the Container App
4. View metrics, logs, and revisions

## Scaling

### Manual Scaling

Update the replica count:

```bash
az containerapp update \
  --name <container-app-name> \
  --resource-group <rg-name> \
  --min-replicas 2 \
  --max-replicas 5
```

### Auto-scaling

The app automatically scales based on HTTP request concurrency (configured at 10 concurrent requests per replica).

## Cleanup

To delete all resources:

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

## Cost Optimization

- **Development**: Use 1 replica, scale down when not in use
- **Production**: Use auto-scaling with appropriate min/max replicas
- **Container Registry**: Use Basic SKU for development, consider Standard/Premium for production

## Security Considerations

1. **Service Principal**: Use least-privilege access with specific resource group scope
2. **Secrets**: Never commit secrets to Git; use GitHub Secrets or Azure Key Vault
3. **Container Image**: The Dockerfile uses a non-root user for better security
4. **Network**: Consider using private endpoints for production workloads
5. **Authentication**: Add Azure AD authentication for production applications

## Additional Resources

- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [GitHub Actions for Azure](https://docs.microsoft.com/en-us/azure/developer/github/github-actions)
- [Spring Boot on Azure](https://docs.microsoft.com/en-us/azure/developer/java/spring-framework/)

## Support

For issues specific to this deployment setup, please open an issue in the repository.
For Azure-specific issues, refer to [Azure Support](https://azure.microsoft.com/en-us/support/).
