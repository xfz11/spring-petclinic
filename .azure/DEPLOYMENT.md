# Azure Container Apps Deployment

This document provides instructions for deploying the Spring PetClinic application to Azure Container Apps.

## Prerequisites

- Azure subscription (ID: a4ab3025-1b32-4394-92e0-d07c1ebf3787)
- Azure CLI installed locally
- Azure Developer CLI (azd) installed locally
- Docker installed (for local testing)
- GitHub account with repository access

## Architecture

The deployment includes:
- **Azure Container Apps**: Hosts the Spring Boot application
- **Azure Container Registry**: Stores Docker images
- **Application Insights**: Application monitoring and telemetry
- **Log Analytics Workspace**: Centralized logging
- **User-Assigned Managed Identity**: Secure authentication between services

## Local Deployment

### 1. Install Prerequisites

```bash
# Install Azure CLI (if not installed)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | bash

# Verify installations
az --version
azd version
```

### 2. Login to Azure

```bash
az login
az account set --subscription a4ab3025-1b32-4394-92e0-d07c1ebf3787
```

### 3. Create and Configure Environment

```bash
# Create a new azd environment
azd env new spring-petclinic-dev --no-prompt

# Set required environment variables
azd env set AZURE_SUBSCRIPTION_ID a4ab3025-1b32-4394-92e0-d07c1ebf3787
azd env set AZURE_LOCATION eastus2
```

Available regions: eastus2, centralus, westus2, swedencentral, southeastasia

### 4. Preview Infrastructure

```bash
# Dry run to validate Bicep files
azd provision --preview --no-prompt
```

### 5. Deploy Application

```bash
# Provision infrastructure and deploy application
azd up --no-prompt
```

This command will:
1. Create a resource group
2. Deploy Azure Container Registry
3. Deploy Log Analytics and Application Insights
4. Deploy Container Apps Environment
5. Build and push Docker image
6. Deploy the Container App with the image

### 6. Access the Application

After deployment completes, the application URL will be displayed. It will look like:
```
https://azapp-<token>-web.happysky-12345678.eastus2.azurecontainerapps.io
```

### 7. Monitor the Application

```bash
# View environment variables and outputs
azd env get-values

# View logs (requires azd extension or use Azure Portal)
# Visit Azure Portal > Container Apps > your app > Log stream
```

## GitHub Actions CI/CD Pipeline

### Setup

1. **Create GitHub Secrets**:
   
   Go to your repository Settings > Secrets and variables > Actions, and add:
   
   - `AZURE_CLIENT_ID`: Service Principal Client ID for GitHub OIDC
   - `AZURE_TENANT_ID`: Azure Tenant ID (72f988bf-86f1-41af-91ab-2d7cd011db47)
   - `AZURE_SUBSCRIPTION_ID`: Azure Subscription ID (a4ab3025-1b32-4394-92e0-d07c1ebf3787)

2. **Configure OIDC for GitHub Actions**:

   ```bash
   # Create an Azure AD Application and Service Principal for GitHub OIDC
   az ad app create --display-name "GitHub-SpringPetClinic-OIDC"
   
   # Note the appId from the output
   APP_ID="<appId from previous command>"
   
   # Create service principal
   az ad sp create --id $APP_ID
   
   # Get the object ID
   OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)
   
   # Create federated credentials for GitHub Actions
   az ad app federated-credential create --id $APP_ID --parameters '{
     "name": "github-spring-petclinic",
     "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:xfz11/spring-petclinic:ref:refs/heads/main",
     "audiences": ["api://AzureADTokenExchange"]
   }'
   
   # Assign Contributor role to the subscription
   az role assignment create --assignee $APP_ID \
     --role Contributor \
     --scope /subscriptions/a4ab3025-1b32-4394-92e0-d07c1ebf3787
   ```

3. **Trigger Deployment**:
   
   The workflow triggers on:
   - Push to `main` or `copilot/deploy-app-to-azure-container` branches
   - Manual trigger via `workflow_dispatch`

### Workflow Steps

1. **Build**: Compiles Java application with Maven
2. **Provision and Deploy**: Uses `azd up` to provision and deploy to Azure

## Infrastructure Details

### Resource Naming Convention

All resources use the pattern: `az{prefix}{token}` where token is generated from:
```
uniqueString(subscription().id, location, environmentName)
```

Example names:
- Container Registry: `acr<token>`
- Container App: `azapp<token>-web`
- Log Analytics: `azlog<token>`
- Application Insights: `azai<token>`
- Managed Identity: `azid<token>`

### Security Configuration

- User-Assigned Managed Identity has AcrPull role on Container Registry
- Container Apps uses managed identity (not admin credentials) to pull images
- Public network access enabled for development
- CORS enabled for cross-origin requests

### Environment Variables

The application is configured with:
- `SPRING_PROFILES_ACTIVE=default` (uses H2 in-memory database)
- `SERVER_PORT=8080`
- `APPLICATIONINSIGHTS_CONNECTION_STRING` (auto-configured)

## Troubleshooting

### Build Fails

```bash
# Check Maven build locally
./mvnw clean package

# Build Docker image locally
docker build -t spring-petclinic:test .

# Run locally
docker run -p 8080:8080 spring-petclinic:test
```

### Deployment Fails

```bash
# Check Bicep syntax
az bicep build --file infra/main.bicep

# View deployment logs
az deployment sub show --name <deployment-name>

# Tear down and retry
azd down --force --no-prompt
azd up --no-prompt
```

### Application Not Responding

1. Check Container App logs in Azure Portal
2. Verify ingress configuration
3. Check Application Insights for errors
4. Verify the container is running: Azure Portal > Container App > Revision management

## Cleanup

To delete all Azure resources:

```bash
azd down --force --no-prompt
```

Or manually delete the resource group:

```bash
az group delete --name rg-spring-petclinic-dev --yes --no-wait
```

## Cost Estimation

- **Azure Container Apps**: Consumption plan, pay for actual usage
- **Azure Container Registry**: Basic tier (~$5/month)
- **Log Analytics**: Pay per GB ingested
- **Application Insights**: Free tier available (up to 5 GB/month)

Estimated cost for development: $5-20/month depending on usage.

## Next Steps

1. Configure custom domain (optional)
2. Add SSL certificate (optional)
3. Set up database (PostgreSQL or MySQL) for production
4. Configure scaling rules based on load
5. Set up alerts and monitoring dashboards
6. Implement CI/CD pipeline enhancements (testing, security scanning)

## Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Spring Boot on Azure](https://learn.microsoft.com/en-us/azure/developer/java/spring/)
