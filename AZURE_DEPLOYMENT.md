# Azure Deployment Guide for Spring PetClinic

This guide explains how to deploy the Spring PetClinic application to Azure using Azure Developer CLI (azd) with Bicep for infrastructure provisioning.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) installed
- An Azure subscription
- Docker installed (for building container images)

## Architecture

This deployment uses the following Azure services:
- **Azure Container Apps**: Hosts the Spring Boot application (non-AKS hosting)
- **Azure Container Registry**: Stores the Docker images
- **Azure Database for PostgreSQL Flexible Server**: Production database
- **Container Apps Environment**: Managed environment for running containers

## Deployment Steps

### 1. Login to Azure

```bash
azd auth login
az login
```

### 2. Initialize the Azure environment

```bash
azd init
```

When prompted:
- Environment name: Enter a unique name (e.g., `petclinic-dev`)
- Azure location: Select your preferred region (e.g., `eastus`)

### 3. Set required environment variables

```bash
# Generate a secure password for PostgreSQL
azd env set POSTGRES_ADMIN_PASSWORD '<your-secure-password>'
```

### 4. Provision Azure resources

This command creates all the required Azure infrastructure using Bicep templates:

```bash
azd provision
```

This will create:
- Resource Group
- Container Registry
- Container Apps Environment
- PostgreSQL Flexible Server
- Container App for the web service

### 5. Deploy the application

Build and deploy the application to Azure:

```bash
azd deploy
```

This will:
- Build the Docker image
- Push it to Azure Container Registry
- Deploy it to Azure Container Apps

### 6. Access the application

After deployment completes, azd will display the application URL. You can also get it with:

```bash
azd env get-values | grep WEB_URI
```

Or view all outputs:

```bash
azd env get-values
```

## Configuration

### Environment Variables

The application is configured with the following environment variables in Azure:

- `SPRING_PROFILES_ACTIVE`: Set to `postgres` for production database
- `SPRING_DATASOURCE_URL`: JDBC connection string to PostgreSQL
- `SPRING_DATASOURCE_USERNAME`: PostgreSQL admin username
- `SPRING_DATASOURCE_PASSWORD`: PostgreSQL admin password (stored as secret)

### Database

The PostgreSQL database is created with:
- Database name: `petclinic`
- Schema and data are initialized on first startup using Spring Boot's schema initialization

## Monitoring

The application includes Spring Boot Actuator endpoints for monitoring:
- Health check: `https://<your-app-url>/actuator/health`
- Info: `https://<your-app-url>/actuator/info`

## Cleanup

To delete all Azure resources:

```bash
azd down
```

## Troubleshooting

### Check application logs

```bash
azd logs
```

### View Container App logs in Azure Portal

1. Go to Azure Portal
2. Navigate to your resource group
3. Open the Container App
4. Go to "Log stream" or "Console"

### Common Issues

1. **Build fails**: Ensure Docker is running and you have internet connectivity
2. **PostgreSQL connection fails**: Check firewall rules in the Azure Portal
3. **Deployment timeout**: Container Apps might need more time to pull large images

## Infrastructure Details

The Bicep templates are located in the `infra/` directory:

- `main.bicep`: Main orchestration file
- `core/host/container-app.bicep`: Container App configuration
- `core/host/container-registry.bicep`: Container Registry configuration
- `core/host/container-apps-environment.bicep`: Container Apps Environment
- `core/database/postgresql/flexibleserver.bicep`: PostgreSQL database configuration

## Development

### Local testing with Docker

Build and run locally:

```bash
docker build -t spring-petclinic .
docker run -p 8080:8080 spring-petclinic
```

Access at: http://localhost:8080

### Update deployment

After making code changes:

```bash
azd deploy
```

## Support

For issues specific to this deployment:
- Check the [Azure Developer CLI documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- Review [Azure Container Apps documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
