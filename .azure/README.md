# Azure Container Apps Deployment Guide

This guide explains how to deploy the Spring PetClinic application to Azure Container Apps using Azure Developer CLI (azd).

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (version 2.40.0 or later)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) (azd)
- [Docker](https://docs.docker.com/get-docker/) (for local testing)
- An Azure subscription

## Architecture

The deployment creates the following Azure resources:

- **Azure Container Apps**: Hosts the Spring PetClinic application
- **Azure Container Registry**: Stores the Docker images
- **Azure Container Apps Environment**: Manages the container app infrastructure
- **Application Insights**: Monitors application performance and logs
- **Log Analytics Workspace**: Stores logs and metrics
- **Key Vault**: Stores application secrets (prepared for future use)
- **User-Assigned Managed Identity**: Provides secure authentication between services

## Local Setup

### 1. Install Tools

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | bash

# Verify installations
az --version
azd version
```

### 2. Login to Azure

```bash
# Login to Azure
az login

# Set your default subscription (if you have multiple)
az account set --subscription <subscription-id>

# Login to Azure Developer CLI
azd auth login
```

### 3. Initialize Environment

```bash
# Create a new azd environment
azd env new <your-env-name>

# Example: azd env new petclinic-dev
```

This will prompt you for:
- **Environment name**: A unique name for your environment (e.g., `petclinic-dev`)
- **Azure subscription**: Select your Azure subscription
- **Azure location**: Select a region (e.g., `eastus`, `westus2`, `westeurope`)

### 4. Deploy to Azure

```bash
# Deploy infrastructure and application in one command
azd up

# Or deploy separately:
# 1. Provision infrastructure
azd provision

# 2. Deploy application
azd deploy
```

The first deployment will take several minutes as it:
1. Creates all Azure resources
2. Builds the Docker image
3. Pushes the image to Azure Container Registry
4. Deploys the container to Azure Container Apps

### 5. Access Your Application

After deployment completes, azd will display the application URL:

```
Deploying services (azd deploy)

  (✓) Done: Deploying service petclinic
  - Endpoint: https://azca<unique-id>.example.azurecontainerapps.io/
```

Visit the URL in your browser to access the Spring PetClinic application.

## Monitoring and Logs

### View Application Logs

```bash
# View logs from Azure Developer CLI
azd monitor

# Or view logs using Azure CLI
az containerapp logs show --name <container-app-name> --resource-group <resource-group-name>
```

### View Application Insights

1. Go to the [Azure Portal](https://portal.azure.com)
2. Navigate to your resource group
3. Open the Application Insights resource
4. View metrics, logs, and performance data

## GitHub Actions CI/CD

The repository includes a GitHub Actions workflow (`.github/workflows/azure-deploy.yml`) for automated deployments.

### Setup GitHub Actions

1. **Configure Federated Identity** (Recommended for secure authentication):

   ```bash
   # Run this command to set up GitHub Actions with federated credentials
   azd pipeline config
   ```

   This will:
   - Create a service principal with federated credentials
   - Set up the required GitHub secrets/variables
   - Configure the workflow to use OIDC authentication

2. **Required GitHub Variables** (automatically set by `azd pipeline config`):
   - `AZURE_CLIENT_ID`: Service principal client ID
   - `AZURE_TENANT_ID`: Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
   - `AZURE_ENV_NAME`: Environment name
   - `AZURE_LOCATION`: Azure region

3. **Trigger Deployment**:
   - Push to `main` branch
   - Or manually trigger via GitHub Actions UI

## Configuration

### Environment Variables

The application uses the following environment variables (configured in `infra/main.bicep`):

- `SPRING_PROFILES_ACTIVE`: Set to `default` (uses H2 in-memory database)
- `SERVER_PORT`: Application port (8080)
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights connection string (auto-configured)

### Scaling

The Container App is configured to scale:
- **Minimum replicas**: 1
- **Maximum replicas**: 10
- **Resources per replica**: 0.5 vCPU, 1 GiB memory

To modify scaling settings, update the `template.scale` section in `infra/main.bicep`.

## Cleanup

To delete all Azure resources:

```bash
# Delete all resources
azd down

# Delete with confirmation
azd down --force --purge
```

## Troubleshooting

### Deployment Fails

1. Check deployment logs:
   ```bash
   azd provision --debug
   ```

2. Verify Azure CLI login:
   ```bash
   az account show
   ```

3. Check resource availability in your region:
   ```bash
   az provider show --namespace Microsoft.App --query "resourceTypes[?resourceType=='containerApps'].locations"
   ```

### Application Not Starting

1. View container logs:
   ```bash
   az containerapp logs show --name <container-app-name> --resource-group <resource-group-name> --follow
   ```

2. Check Application Insights for errors:
   - Go to Azure Portal → Application Insights → Failures

### Build Failures

1. Test Docker build locally:
   ```bash
   docker build -t petclinic:test .
   docker run -p 8080:8080 petclinic:test
   ```

2. Check Maven build:
   ```bash
   ./mvnw clean package
   ```

## Additional Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Spring PetClinic Documentation](../README.md)

## Support

For issues related to:
- **Azure deployment**: Open an issue in this repository
- **Spring PetClinic application**: See the main [README.md](../README.md)
- **Azure services**: Contact [Azure Support](https://azure.microsoft.com/support/)
