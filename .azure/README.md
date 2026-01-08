# Azure Deployment Guide for Spring PetClinic

This guide will help you deploy the Spring PetClinic application to Azure using the Azure Developer CLI (azd).

## Prerequisites

- Azure subscription
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) installed
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) installed
- Java 17 or later
- Maven

## Architecture

The deployment creates the following Azure resources:

- **Azure App Service (Linux)**: Hosts the Spring Boot application with Java 17 runtime
- **App Service Plan (B1)**: Basic tier plan for development/testing
- **Application Insights**: Application performance monitoring
- **Log Analytics Workspace**: Centralized logging
- **User-Assigned Managed Identity**: Secure authentication to Azure services

## Deployment Steps

### 1. Login to Azure

```bash
az login
```

### 2. Initialize AZD Environment

Create a new environment (e.g., "dev"):

```bash
azd env new dev --no-prompt
```

### 3. Set Environment Variables

Set your Azure subscription ID:

```bash
azd env set AZURE_SUBSCRIPTION_ID $(az account show --query id -o tsv)
```

Set the Azure location (e.g., eastus, westus2, centralus):

```bash
azd env set AZURE_LOCATION eastus
```

### 4. Preview Infrastructure

Run a dry-run to see what resources will be created:

```bash
azd provision --preview --no-prompt
```

### 5. Deploy Application

Deploy the infrastructure and application:

```bash
azd up --no-prompt
```

This command will:
1. Build the Spring Boot application using Maven
2. Create Azure resources (App Service, Application Insights, etc.)
3. Deploy the application to App Service

### 6. Access Your Application

After deployment completes, azd will output the application URL. You can also get it with:

```bash
azd env get-values | grep WEB_APP_URI
```

Visit the URL in your browser to see the Spring PetClinic application running on Azure.

## Application Configuration

The deployed application uses:
- **Runtime**: Java 17 on Linux
- **Database**: H2 in-memory database (default)
- **Port**: 8080 (internal)
- **HTTPS**: Enabled with automatic certificate

## Monitoring

- **Application Insights**: View application telemetry, performance metrics, and logs in the Azure Portal
- **App Service Logs**: Access via Azure Portal or Azure CLI

To view logs:

```bash
az webapp log tail --name <app-name> --resource-group <resource-group-name>
```

## Cleanup

To delete all Azure resources created by this deployment:

```bash
azd down
```

## Troubleshooting

### Build Failures

If the Maven build fails, you can build locally first:

```bash
./mvnw clean package -DskipTests
```

### Deployment Issues

Check the deployment logs:

```bash
azd deploy --debug
```

### Application Issues

View application logs in Azure Portal:
1. Navigate to your App Service
2. Go to "Log stream" or "Logs" under Monitoring

## Next Steps

- Configure a persistent database (MySQL or PostgreSQL)
- Set up CI/CD with GitHub Actions
- Enable custom domain and SSL certificate
- Scale the App Service Plan for production workloads

## Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Spring PetClinic Documentation](../README.md)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
