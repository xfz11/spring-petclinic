# Azure Deployment Guide for Spring PetClinic

This directory contains Bicep Infrastructure as Code (IaC) files to deploy the Spring PetClinic application to Azure.

## Architecture

The deployment creates the following Azure resources:

- **Azure Container Registry (ACR)**: Stores the containerized Spring Boot application
- **Azure Container Apps Environment**: Provides the runtime environment for containers
- **Azure Container App**: Hosts the Spring PetClinic application
- **Azure Database for PostgreSQL Flexible Server**: Provides a managed PostgreSQL database
- **Log Analytics Workspace**: Collects logs and metrics from the Container Apps Environment

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az version
   ```
   Install from: https://docs.microsoft.com/cli/azure/install-azure-cli

2. **Azure subscription** with appropriate permissions to create resources

3. **Bicep CLI** (included with Azure CLI 2.20.0 and later)
   ```bash
   az bicep version
   ```

4. **Docker** installed for building container images
   ```bash
   docker --version
   ```

5. **Logged into Azure**
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

## Deployment Steps

### 1. Set Environment Variables

```bash
# Set your Azure subscription
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"

# Set a strong password for PostgreSQL
export POSTGRES_PASSWORD="<YourSecurePassword123!>"

# Set resource group name (optional, will use default from bicepparam)
export RESOURCE_GROUP_NAME="rg-petclinic-dev"

# Set location (optional)
export LOCATION="eastus"
```

### 2. Deploy Infrastructure

Deploy the Bicep template to your Azure subscription:

```bash
# Navigate to the project root
cd /path/to/spring-petclinic

# Deploy using bicepparam file
az deployment sub create \
  --name petclinic-deployment-$(date +%Y%m%d-%H%M%S) \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --parameters postgresAdminPassword="$POSTGRES_PASSWORD"
```

Or deploy with inline parameters:

```bash
az deployment sub create \
  --name petclinic-deployment-$(date +%Y%m%d-%H%M%S) \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters resourceGroupName="$RESOURCE_GROUP_NAME" \
  --parameters location="$LOCATION" \
  --parameters postgresAdminLogin="petclinicadmin" \
  --parameters postgresAdminPassword="$POSTGRES_PASSWORD"
```

The deployment will take approximately 5-10 minutes.

### 3. Get Deployment Outputs

After deployment completes, retrieve the outputs:

```bash
# Get outputs from deployment
DEPLOYMENT_NAME=$(az deployment sub list --query "[0].name" -o tsv)
az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs
```

Save the following outputs:
- `containerRegistryLoginServer`: ACR login server
- `containerRegistryName`: ACR name
- `containerAppUrl`: URL of your deployed application
- `postgresqlFqdn`: PostgreSQL server FQDN

### 4. Build and Push Container Image

```bash
# Get ACR credentials
export ACR_NAME=$(az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs.containerRegistryName.value -o tsv)
export ACR_LOGIN_SERVER=$(az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs.containerRegistryLoginServer.value -o tsv)

# Login to ACR
az acr login --name $ACR_NAME

# Build the Docker image
docker build -t petclinic:latest .

# Tag the image for ACR
docker tag petclinic:latest ${ACR_LOGIN_SERVER}/petclinic:latest

# Push the image to ACR
docker push ${ACR_LOGIN_SERVER}/petclinic:latest
```

Alternative: Build and push in one step using ACR build:

```bash
az acr build --registry $ACR_NAME --image petclinic:latest .
```

### 5. Update Container App

After pushing the image, the Container App will automatically pull and deploy the new image. You can monitor the deployment:

```bash
# Get the Container App name
export CONTAINER_APP_NAME=$(az containerapp list --resource-group $RESOURCE_GROUP_NAME --query "[0].name" -o tsv)

# Check revision status
az containerapp revision list \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "[].{Name:name, Active:properties.active, Created:properties.createdTime, Replicas:properties.replicas}" \
  --output table
```

### 6. Access the Application

Get the application URL:

```bash
export APP_URL=$(az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs.containerAppUrl.value -o tsv)
echo "Application URL: https://$APP_URL"
```

Open the URL in your browser to access the Spring PetClinic application.

## Configuration

### Environment Variables

The Container App is configured with the following environment variables:

- `SPRING_PROFILES_ACTIVE=postgres`: Activates PostgreSQL profile
- `POSTGRES_URL`: JDBC connection string to PostgreSQL
- `POSTGRES_USER`: PostgreSQL admin username
- `POSTGRES_PASS`: PostgreSQL admin password (stored as secret)
- `JAVA_OPTS`: JVM memory settings

### Scaling

The Container App is configured with auto-scaling:
- **Min replicas**: 1
- **Max replicas**: 3
- **Scaling rule**: HTTP concurrent requests (10 per instance)

To modify scaling settings, update the `container-app.bicep` module.

### Database Configuration

PostgreSQL Flexible Server is configured with:
- **Version**: PostgreSQL 16
- **SKU**: Standard_B1ms (Burstable)
- **Storage**: 32 GB with auto-grow enabled
- **Backup**: 7-day retention
- **Public network access**: Enabled (for Azure services)

For production, consider:
- Upgrading to GeneralPurpose or MemoryOptimized tier
- Enabling geo-redundant backup
- Configuring high availability
- Restricting network access with VNet integration

## Monitoring and Logs

### View Application Logs

```bash
# Stream logs
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --follow

# View recent logs
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --tail 100
```

### Access Log Analytics

```bash
# Get Log Analytics Workspace ID
export LOG_ANALYTICS_ID=$(az monitor log-analytics workspace list \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "[0].customerId" -o tsv)

echo "Log Analytics Workspace ID: $LOG_ANALYTICS_ID"
```

Query logs in Azure Portal:
1. Go to Azure Portal
2. Navigate to Log Analytics Workspaces
3. Select your workspace
4. Use Logs to query ContainerAppConsoleLogs_CL

### Health Checks

The application exposes actuator endpoints:

- **Liveness**: `https://$APP_URL/actuator/health/liveness`
- **Readiness**: `https://$APP_URL/actuator/health/readiness`
- **General health**: `https://$APP_URL/actuator/health`

## Updating the Application

To deploy a new version:

```bash
# Build and push new image with version tag
docker build -t petclinic:v1.1.0 .
docker tag petclinic:v1.1.0 ${ACR_LOGIN_SERVER}/petclinic:v1.1.0
docker push ${ACR_LOGIN_SERVER}/petclinic:v1.1.0

# Update the container app with new image
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --image ${ACR_LOGIN_SERVER}/petclinic:v1.1.0
```

Or redeploy infrastructure with new tag:

```bash
az deployment sub create \
  --name petclinic-update-$(date +%Y%m%d-%H%M%S) \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --parameters containerImageTag="v1.1.0" \
  --parameters postgresAdminPassword="$POSTGRES_PASSWORD"
```

## Troubleshooting

### Container App not starting

Check the logs:
```bash
az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP_NAME --tail 100
```

Common issues:
- Database connection timeout: Check PostgreSQL firewall rules
- Image pull errors: Verify ACR credentials and image exists
- Memory issues: Adjust JAVA_OPTS or container resources

### Database connection issues

Test PostgreSQL connectivity:
```bash
# Get PostgreSQL FQDN
export POSTGRES_FQDN=$(az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs.postgresqlFqdn.value -o tsv)

# Test connection (requires psql client)
psql "host=$POSTGRES_FQDN port=5432 dbname=petclinic user=petclinicadmin sslmode=require"
```

### View Container App configuration

```bash
az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --output yaml
```

## Cleanup

To remove all resources:

```bash
# Delete resource group (removes all resources)
az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait

# Or delete subscription-level deployment
az deployment sub delete --name $DEPLOYMENT_NAME
```

## Cost Optimization

For development environments:
- Use Burstable tier for PostgreSQL
- Set minReplicas to 0 to scale to zero when not in use
- Use Basic SKU for Container Registry

For production:
- Consider Reserved Instances for cost savings
- Enable Azure Advisor recommendations
- Monitor costs with Azure Cost Management

## Security Best Practices

1. **Use managed identities**: Replace admin credentials with managed identity for ACR access
2. **Enable VNet integration**: Remove public access to PostgreSQL
3. **Use Azure Key Vault**: Store secrets in Key Vault and reference them
4. **Enable SSL/TLS**: Enforce SSL connections to PostgreSQL
5. **Regular updates**: Keep container images and dependencies updated
6. **Enable Microsoft Defender**: For Container Apps and PostgreSQL

## Additional Resources

- [Azure Container Apps Documentation](https://docs.microsoft.com/azure/container-apps/)
- [Azure Database for PostgreSQL Documentation](https://docs.microsoft.com/azure/postgresql/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/azure/container-registry/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

## Support

For issues related to:
- **Spring PetClinic**: See [GitHub Issues](https://github.com/spring-projects/spring-petclinic/issues)
- **Azure deployment**: Create an issue in your repository
- **Azure services**: Contact Azure Support
