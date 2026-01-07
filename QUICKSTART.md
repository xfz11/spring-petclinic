# Quick Start Guide - Azure Container Apps Deployment

This is a quick reference guide to deploy the Spring PetClinic application to Azure Container Apps.

## Prerequisites

- Azure CLI installed and configured
- Docker installed (for local deployment script)
- Azure subscription with appropriate permissions
- GitHub account (for CI/CD pipeline)

## Option 1: Manual Deployment (Using the Script)

### Step 1: Login to Azure
```bash
az login
```

### Step 2: Deploy the Application
```bash
# Make the script executable (if needed)
chmod +x deploy.sh

# Run the deployment script
./deploy.sh -g <your-resource-group-name> -l eastus -e dev
```

### Example
```bash
./deploy.sh -g petclinic-demo-rg -l eastus -e dev
```

The script will:
- Create the resource group
- Deploy Azure Container Registry
- Build and push the Docker image
- Deploy the Container App
- Display the application URL

### Access Your Application
After deployment, access your application at the URL displayed by the script:
```
https://<app-name>.<region>.azurecontainerapps.io
```

## Option 2: CI/CD with GitHub Actions

### Step 1: Create Azure Service Principal

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal with federated credentials
az ad sp create-for-rbac \
  --name "petclinic-github-actions" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

**Save the output JSON!** You'll need the values for GitHub secrets.

### Step 2: Configure GitHub Secrets

Go to your repository on GitHub:
1. Click **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `AZURE_CLIENT_ID` | Service Principal Application ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `abcdef01-2345-6789-abcd-ef0123456789` |
| `AZURE_RESOURCE_GROUP` | Resource Group Name | `petclinic-rg` |

### Step 3: Enable Federated Credentials (Recommended)

```bash
# Get the Application ID from the service principal output
APP_ID="<your-app-id-from-step-1>"

# Configure federated credential for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<your-github-username>/<your-repo-name>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Replace `<your-github-username>/<your-repo-name>` with your actual repository path (e.g., `xfz11/spring-petclinic`).

### Step 4: Trigger Deployment

**Automatic Deployment:**
- Push changes to the `main` branch
- The workflow will automatically build and deploy

**Manual Deployment:**
1. Go to **Actions** tab in your repository
2. Select **Deploy to Azure Container Apps** workflow
3. Click **Run workflow**
4. Select environment (dev/test/prod)
5. Click **Run workflow** button

## Monitoring and Management

### View Application Logs
```bash
# Get container app name
CONTAINER_APP_NAME=$(az containerapp list \
  --resource-group <your-rg> \
  --query "[0].name" -o tsv)

# Stream logs
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group <your-rg> \
  --follow
```

### Check Application Health
```bash
# Get the app URL
APP_URL=$(az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group <your-rg> \
  --query properties.configuration.ingress.fqdn -o tsv)

# Check health
curl https://$APP_URL/actuator/health
```

### Scale the Application
```bash
# Update min/max replicas
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group <your-rg> \
  --min-replicas 2 \
  --max-replicas 5
```

## Files Overview

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage Docker build for the application |
| `.dockerignore` | Files to exclude from Docker build |
| `infra/main.bicep` | Azure infrastructure as code template |
| `infra/main.parameters.json` | Default parameters for Bicep template |
| `deploy.sh` | Automated deployment script |
| `.github/workflows/azure-container-apps.yml` | CI/CD pipeline |
| `AZURE_DEPLOYMENT.md` | Comprehensive deployment documentation |

## Common Issues

### Issue: Service Principal Creation Error
**Solution:** Ensure you have the required permissions in Azure AD. You may need to ask your Azure administrator.

### Issue: Docker Build Fails
**Solution:** Ensure Docker daemon is running: `docker info`

### Issue: Azure CLI Not Found
**Solution:** Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

### Issue: GitHub Actions Workflow Fails
**Solution:** 
1. Verify all secrets are configured correctly
2. Check the workflow logs for specific error messages
3. Ensure the service principal has Contributor access

## Cleanup

To delete all resources and stop incurring costs:

```bash
az group delete --name <your-resource-group> --yes --no-wait
```

## Cost Estimation

**Development (1 replica, low traffic):**
- Container Apps: ~$10-20/month
- Container Registry: ~$5/month
- Log Analytics: ~$2-5/month
- **Total: ~$17-30/month**

**Production (3 replicas, moderate traffic):**
- Container Apps: ~$50-100/month
- Container Registry: ~$5-20/month
- Log Analytics: ~$10-20/month
- **Total: ~$65-140/month**

## Next Steps

1. ✅ Deploy the application using one of the methods above
2. Configure custom domain (optional)
3. Set up monitoring and alerts
4. Configure authentication (Azure AD, etc.)
5. Review and optimize costs

## Support & Resources

- **Detailed Documentation:** See `AZURE_DEPLOYMENT.md`
- **Azure Container Apps Docs:** https://docs.microsoft.com/en-us/azure/container-apps/
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Azure CLI Reference:** https://docs.microsoft.com/en-us/cli/azure/

---

**Ready to deploy?** Start with Option 1 for a quick test, then set up Option 2 for continuous deployment! 🚀
