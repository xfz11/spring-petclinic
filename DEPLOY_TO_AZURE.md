# Deploy to Azure

This Spring PetClinic application is configured for deployment to Azure using the Azure Developer CLI (azd).

## Quick Start

```bash
# Install Azure Developer CLI (if not already installed)
# See: https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd

# Login to Azure
az login

# Create a new environment and deploy
azd up
```

The `azd up` command will:
1. Prompt for an environment name (e.g., "dev")
2. Prompt for an Azure location (e.g., "eastus")
3. Build the Spring Boot application
4. Provision Azure resources (App Service, Application Insights, etc.)
5. Deploy the application to Azure App Service

## What Gets Deployed

- **Azure App Service**: Linux-based hosting with Java 17
- **Application Insights**: Application monitoring and telemetry
- **Log Analytics**: Centralized logging
- **Managed Identity**: Secure authentication

## Documentation

- **Deployment Guide**: See [.azure/README.md](.azure/README.md)
- **Deployment Plan**: See [.azure/plan.copilot.md](.azure/plan.copilot.md)
- **Summary**: See [.azure/summary.copilot.md](.azure/summary.copilot.md)

## Infrastructure

All infrastructure is defined using Bicep in the `infra/` directory:
- `infra/main.bicep`: Main deployment template
- `infra/resources.bicep`: Azure resources
- `infra/app/web.bicep`: App Service configuration

## Monitoring

After deployment, view your application:
```bash
azd show --endpoint web
```

View logs:
```bash
azd logs --service web
```

## Cleanup

To delete all Azure resources:
```bash
azd down
```

## Learn More

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Spring Boot on Azure](https://learn.microsoft.com/azure/developer/java/spring/)
