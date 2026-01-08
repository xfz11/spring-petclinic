# Deploying Spring PetClinic to Azure

This guide will help you deploy the Spring PetClinic application to Azure using Azure Developer CLI (azd) with Bicep infrastructure as code.

## Architecture Overview

The deployment creates the following Azure resources:

- **Azure App Service**: Hosts the Spring Boot application (Java 17)
- **Azure Database for MySQL**: Persistent database for application data
- **Azure Key Vault**: Securely stores database credentials
- **Application Insights**: Monitors application performance and logs
- **Log Analytics Workspace**: Centralized logging
- **User-Assigned Managed Identity**: Secure access to Azure resources

## Prerequisites

Before you begin, ensure you have:

1. **Azure Subscription**: An active Azure subscription with appropriate permissions
2. **Azure CLI**: Version 2.81.0 or later
   ```bash
   az --version
   ```
   Install: https://learn.microsoft.com/cli/azure/install-azure-cli

3. **Azure Developer CLI (azd)**: Version 1.22.5 or later
   ```bash
   azd version
   ```
   Install: https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd

4. **Java 17**: Required for building the application
   ```bash
   java -version
   ```

5. **Maven**: For building the Spring Boot application (included via Maven wrapper)

## Quick Start

### 1. Clone the Repository (if not already done)
```bash
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
```

### 2. Login to Azure
```bash
az login
```

If you have multiple subscriptions, set the one you want to use:
```bash
az account list -o table
az account set --subscription <subscription-id>
```

### 3. Initialize AZD Environment
```bash
# Create a new environment (e.g., 'dev', 'prod', 'staging')
azd env new dev --no-prompt
```

### 4. Configure Environment Variables
```bash
# Set the environment name (should match step 3)
azd env set AZURE_ENV_NAME dev

# Set the Azure region (choose a region close to your users)
# Examples: eastus2, westus2, centralus, westeurope, eastasia
azd env set AZURE_LOCATION eastus2

# Set a strong password for MySQL administrator
azd env set MYSQL_ADMIN_PASSWORD "YourSecurePassword123!"

# Optional: Set custom MySQL admin username (default: petclinicadmin)
# azd env set MYSQL_ADMIN_LOGIN "myadmin"
```

### 5. Create Resource Group
```bash
# Create the resource group
az group create \
  --name rg-dev-spring-petclinic \
  --location eastus2

# Set the resource group in azd environment
azd env set AZURE_RESOURCE_GROUP rg-dev-spring-petclinic
```

### 6. Deploy to Azure
```bash
# Option A: Deploy everything in one command (recommended for first deployment)
azd up --no-prompt

# Option B: Separate provision and deploy steps
azd provision --no-prompt  # Create infrastructure
azd deploy --no-prompt     # Deploy application
```

The deployment process will:
1. Build the Spring Boot application using Maven
2. Create all Azure resources defined in the Bicep templates
3. Deploy the application to Azure App Service
4. Configure database connections and environment variables

### 7. Access Your Application
After deployment completes, get your application URL:
```bash
azd env get-values | grep APP_SERVICE_URL
```

Or visit the Azure Portal to find your App Service URL.

## Deployment Details

### What Gets Deployed

1. **Infrastructure (via Bicep)**:
   - App Service Plan (B2 - Basic tier)
   - App Service with Java 17 runtime
   - MySQL Flexible Server (Standard_B1ms)
   - Key Vault for secrets
   - Application Insights for monitoring
   - Log Analytics Workspace
   - Managed Identity for secure access

2. **Application**:
   - Spring PetClinic web application
   - Configured to use MySQL database
   - Application Insights integration
   - Health endpoints enabled

### Environment Variables

The following environment variables are automatically configured:

- `SPRING_PROFILES_ACTIVE=mysql` - Uses MySQL profile
- `MYSQL_URL` - Retrieved from Key Vault
- `MYSQL_USER` - Retrieved from Key Vault
- `MYSQL_PASS` - Retrieved from Key Vault
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Application Insights connection

### Security Features

- **HTTPS Only**: All traffic is encrypted
- **Managed Identity**: No passwords stored in code
- **Key Vault**: Database credentials stored securely
- **SSL Required**: MySQL connections use SSL
- **RBAC**: Role-based access control for Key Vault
- **Firewall**: MySQL accessible only from Azure services

## Post-Deployment

### View Application Logs
```bash
# View logs in real-time
azd monitor --overview

# Or use Azure CLI
az webapp log tail \
  --name $(azd env get-values | grep APP_SERVICE_NAME | cut -d'=' -f2) \
  --resource-group rg-dev-spring-petclinic
```

### Access Application Endpoints

The deployed application includes:
- **Home Page**: `https://<your-app>.azurewebsites.net/`
- **Health Check**: `https://<your-app>.azurewebsites.net/actuator/health`
- **Metrics**: `https://<your-app>.azurewebsites.net/actuator/metrics`

### View Application Insights
1. Go to Azure Portal
2. Navigate to your Application Insights resource
3. View:
   - Live Metrics
   - Application Map
   - Performance
   - Failures
   - Logs

## Updating the Application

To deploy application updates:

```bash
# Build and deploy new version
azd deploy --no-prompt
```

To update infrastructure:

```bash
# Modify infra/main.bicep as needed
# Then provision again
azd provision --no-prompt
```

## Scaling

### Scale App Service
```bash
# Scale up (change tier)
az appservice plan update \
  --name <plan-name> \
  --resource-group rg-dev-spring-petclinic \
  --sku P1v2

# Scale out (add instances)
az appservice plan update \
  --name <plan-name> \
  --resource-group rg-dev-spring-petclinic \
  --number-of-workers 3
```

### Scale MySQL
```bash
# Scale up MySQL
az mysql flexible-server update \
  --name <server-name> \
  --resource-group rg-dev-spring-petclinic \
  --sku-name Standard_B2s
```

## Monitoring and Diagnostics

### Check Application Health
```bash
# Get app URL
APP_URL=$(azd env get-values | grep APP_SERVICE_URL | cut -d'=' -f2)

# Check health endpoint
curl $APP_URL/actuator/health

# Check home page
curl -I $APP_URL
```

### View Metrics
```bash
# View App Service metrics
az monitor metrics list \
  --resource <app-service-resource-id> \
  --metric "Requests" "Http5xx" "ResponseTime"
```

### Query Logs
```bash
# Query Application Insights
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "requests | take 10"
```

## Troubleshooting

### Application Won't Start

1. **Check logs**:
   ```bash
   az webapp log tail --name <app-name> --resource-group <rg-name>
   ```

2. **Verify MySQL connection**:
   - Check that MySQL server is running
   - Verify firewall rules allow App Service
   - Check connection string in Key Vault

3. **Check Key Vault access**:
   - Verify Managed Identity has correct permissions
   - Check role assignments in Azure Portal

### Build Fails

1. **Check Java version**: Ensure Java 17 is installed
   ```bash
   java -version
   ```

2. **Check Maven**: Verify Maven wrapper is executable
   ```bash
   ./mvnw --version
   ```

3. **Clean build**:
   ```bash
   ./mvnw clean package -DskipTests
   ```

### Database Connection Issues

1. **Check MySQL firewall**:
   ```bash
   az mysql flexible-server firewall-rule list \
     --name <server-name> \
     --resource-group <rg-name>
   ```

2. **Test connectivity**:
   ```bash
   # From App Service console (portal)
   curl https://<mysql-server>.mysql.database.azure.com:3306
   ```

3. **Verify SSL configuration**: Check that connection string includes `sslMode=REQUIRED`

### Deployment Fails

1. **Validate Bicep**:
   ```bash
   az bicep build --file infra/main.bicep
   ```

2. **Check quota**:
   - Verify you have available quota for resources
   - Check region availability

3. **Review error messages**: Carefully read deployment error messages for specific issues

## Cleanup

To delete all resources and clean up:

```bash
# Delete everything (including resource group)
azd down --force --purge --no-prompt

# Or manually delete resource group
az group delete --name rg-dev-spring-petclinic --yes --no-wait
```

## Cost Optimization

The default deployment uses cost-effective tiers suitable for development:

- **App Service**: B2 Basic (~$56/month)
- **MySQL**: Standard_B1ms Burstable (~$13/month)
- **Key Vault**: Standard (~$0.03 per 10,000 operations)
- **Application Insights**: Pay-as-you-go (~$2.30/GB)

For production, consider:
- Upgrading to Premium App Service tiers for better performance
- Using General Purpose or Business Critical MySQL tiers
- Enabling auto-scaling
- Implementing production-grade monitoring

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Database for MySQL Documentation](https://learn.microsoft.com/azure/mysql/)
- [Spring Boot on Azure](https://learn.microsoft.com/azure/developer/java/spring-framework/)
- [Infrastructure README](./infra/README.md) - Detailed infrastructure documentation

## Support

For issues specific to:
- **Spring PetClinic**: [GitHub Issues](https://github.com/spring-projects/spring-petclinic/issues)
- **Azure Services**: [Azure Support](https://azure.microsoft.com/support/)
- **Azure Developer CLI**: [azd GitHub](https://github.com/Azure/azure-dev)

## Next Steps

After successful deployment:

1. **Configure Custom Domain**: Add your custom domain to the App Service
2. **Enable SSL Certificate**: Set up SSL/TLS certificate
3. **Set Up CI/CD**: Configure GitHub Actions or Azure DevOps for automated deployments
4. **Configure Backup**: Set up automated backups for MySQL
5. **Enable Monitoring Alerts**: Create alerts for critical metrics
6. **Review Security**: Run security scans and implement additional security measures
