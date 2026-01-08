# Spring PetClinic Infrastructure

This directory contains the Azure infrastructure as code (Bicep) files for deploying the Spring PetClinic application to Azure using Azure Developer CLI (azd).

## Files

- **main.bicep**: Main infrastructure definition file that creates all Azure resources
- **main.parameters.json**: Parameters file for the Bicep template

## Azure Resources Created

### Compute Resources
- **Azure App Service (Linux)**: Hosts the Spring PetClinic web application
  - SKU: B2 (Basic, 2 cores, 3.5 GB RAM)
  - Runtime: Java 17
  - Framework: Spring Boot
  
- **App Service Plan**: Hosting plan for the App Service
  - SKU: B2 Basic
  - Linux-based

### Database Resources
- **Azure Database for MySQL Flexible Server**: Persistent database for the application
  - SKU: Standard_B1ms (Burstable, 1 vCore, 2 GiB RAM)
  - Version: MySQL 8.0.21
  - Storage: 32 GB with auto-grow enabled
  
- **MySQL Database**: Named "petclinic"
  - Charset: utf8mb4
  - Collation: utf8mb4_unicode_ci

### Security & Identity Resources
- **User-Assigned Managed Identity**: Provides secure access to Azure resources without storing credentials
- **Azure Key Vault**: Stores sensitive information (database credentials)
  - RBAC authentication enabled
  - Stores: MYSQL_URL, MYSQL_USER, MYSQL_PASS

### Monitoring Resources
- **Application Insights**: Application performance monitoring and diagnostics
- **Log Analytics Workspace**: Central repository for logs and metrics
- **Diagnostic Settings**: Configured on App Service for comprehensive logging

### Network Configuration
- **MySQL Firewall Rule**: Allows connections from Azure services (0.0.0.0)
- **HTTPS Only**: Enforced on App Service
- **SSL Required**: Enforced for MySQL connections

## Prerequisites

1. **Azure CLI** (version 2.81.0 or later)
   ```bash
   az --version
   ```

2. **Azure Developer CLI (azd)** (version 1.22.5 or later)
   ```bash
   azd version
   ```

3. **Azure Subscription**: Active Azure subscription with appropriate permissions

## Deployment Steps

### 1. Login to Azure
```bash
az login
```

### 2. Set Subscription (if you have multiple)
```bash
az account set --subscription <subscription-id>
```

### 3. Create AZD Environment
```bash
azd env new dev --no-prompt
```
Replace `dev` with your preferred environment name (e.g., prod, staging).

### 4. Set Environment Variables
```bash
# Set environment name (same as step 3)
azd env set AZURE_ENV_NAME dev

# Set Azure region (choose based on your requirements)
azd env set AZURE_LOCATION eastus2

# Set MySQL admin password (use a strong password)
azd env set MYSQL_ADMIN_PASSWORD "YourSecurePassword123!"

# Optional: Set custom MySQL admin login (default: petclinicadmin)
azd env set MYSQL_ADMIN_LOGIN petclinicadmin
```

### 5. Create Resource Group
```bash
az group create \
  --name rg-dev-spring-petclinic \
  --location eastus2
```

### 6. Set Resource Group in AZD
```bash
azd env set AZURE_RESOURCE_GROUP rg-dev-spring-petclinic
```

### 7. Preview Infrastructure Changes (Optional)
```bash
azd provision --preview --no-prompt
```

### 8. Deploy Application
```bash
# Option A: Provision and deploy in one step
azd up --no-prompt

# Option B: Separate steps
azd provision --no-prompt  # Create infrastructure
azd deploy --no-prompt     # Deploy application
```

## Deployment Outputs

After successful deployment, the following outputs will be available:

- **APP_SERVICE_URL**: The URL of your deployed application
- **MYSQL_SERVER_FQDN**: Fully qualified domain name of the MySQL server
- **AZURE_KEY_VAULT_NAME**: Name of the Key Vault
- **APPLICATIONINSIGHTS_NAME**: Name of Application Insights instance

To view outputs:
```bash
azd env get-values
```

## Monitoring and Logs

### View Application Logs
```bash
# Using azd
azd monitor --overview

# Using Azure CLI
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

### Access Application Insights
```bash
# Get Application Insights details
az monitor app-insights component show \
  --app <app-insights-name> \
  --resource-group <resource-group-name>
```

## Updating Infrastructure

To update the infrastructure after making changes to `main.bicep`:

```bash
azd provision --no-prompt
```

## Cleanup

To delete all resources:

```bash
# Delete azd environment and all associated resources
azd down --force --purge --no-prompt

# Or manually delete the resource group
az group delete --name rg-dev-spring-petclinic --yes --no-wait
```

## Security Considerations

1. **Managed Identity**: The application uses a User-Assigned Managed Identity to access Key Vault, eliminating the need to store credentials in code.

2. **Key Vault Secrets**: Database credentials are stored in Azure Key Vault and referenced via Key Vault references in App Service configuration.

3. **CORS Configuration**: By default, CORS is configured to allow requests from Azure Web Apps (*.azurewebsites.net) and localhost for development. Update the allowedOrigins in main.bicep if you need to allow other domains.

3. **SSL/TLS**: 
   - HTTPS is enforced on the App Service
   - MySQL connections require SSL (sslMode=REQUIRED)
   - Minimum TLS version is 1.2

4. **Network Security**: 
   - MySQL firewall allows only Azure services by default
   - Add specific IP rules if accessing from outside Azure

5. **RBAC**: Key Vault uses Azure RBAC with the Managed Identity assigned the "Key Vault Secrets Officer" role.

## Customization

### Change App Service SKU
Edit `main.bicep` and modify the `appServicePlan` resource:
```bicep
sku: {
  name: 'P1v2'  // Change to desired SKU
  tier: 'PremiumV2'
}
```

### Change MySQL SKU
Edit `main.bicep` and modify the `mysqlServer` resource:
```bicep
sku: {
  name: 'Standard_B2s'  // Change to desired SKU
  tier: 'Burstable'
}
```

### Add Custom Domain
Add a custom domain configuration to the App Service resource in `main.bicep`.

## Troubleshooting

### Build Fails
- Ensure Java 17 is installed: `java -version`
- Check Maven is accessible: `./mvnw --version`
- Review build logs in the console

### Deployment Fails
- Check Bicep validation: `az bicep build --file infra/main.bicep`
- Verify all required parameters are set: `azd env get-values`
- Check Azure CLI authentication: `az account show`

### Application Not Starting
- Check App Service logs: `az webapp log tail --name <app-name> --resource-group <rg-name>`
- Verify MySQL connection: Check that firewall rules allow App Service IP
- Verify Key Vault access: Ensure Managed Identity has correct permissions

### Database Connection Issues
- Verify MySQL server is running
- Check firewall rules in Azure Portal
- Verify SSL certificate configuration
- Check connection string in Key Vault

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Database for MySQL Documentation](https://learn.microsoft.com/azure/mysql/)
- [Spring Boot on Azure Documentation](https://learn.microsoft.com/azure/developer/java/spring-framework/)
