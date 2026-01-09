# Spring PetClinic Azure Deployment Plan

## Overview

This document outlines the complete provision-and-deploy plan for deploying the Spring PetClinic application to Azure using Azure Developer CLI (azd) with Bicep infrastructure templates.

## Deployment Architecture

### Hosting Configuration
- **Deploy Tool**: Azure Developer CLI (azd)
- **Infrastructure as Code**: Bicep
- **Hosting Service**: Azure Container Apps (non-AKS)
- **Container Registry**: Azure Container Registry
- **Database**: Azure Database for PostgreSQL Flexible Server

### Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Subscription                      │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Resource Group                            │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐     │  │
│  │  │     Azure Container Registry                 │     │  │
│  │  │     - Stores Docker images                   │     │  │
│  │  └──────────────────────────────────────────────┘     │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐     │  │
│  │  │     Container Apps Environment               │     │  │
│  │  │                                              │     │  │
│  │  │  ┌────────────────────────────────────┐     │     │  │
│  │  │  │  Spring PetClinic Container App   │     │     │  │
│  │  │  │  - Spring Boot Application        │     │     │  │
│  │  │  │  - Port 8080                      │     │     │  │
│  │  │  │  - Auto-scaling enabled           │     │     │  │
│  │  │  └────────────────────────────────────┘     │     │  │
│  │  └──────────────────────────────────────────────┘     │  │
│  │                          │                             │  │
│  │                          │                             │  │
│  │                          ▼                             │  │
│  │  ┌──────────────────────────────────────────────┐     │  │
│  │  │   PostgreSQL Flexible Server                │     │  │
│  │  │   - Database: petclinic                     │     │  │
│  │  │   - Burstable tier                          │     │  │
│  │  │   - 32GB storage                            │     │  │
│  │  └──────────────────────────────────────────────┘     │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Files Created

### Configuration Files
1. **azure.yaml** - Azure Developer CLI configuration
   - Defines the web service
   - Specifies Java language and Container App hosting
   - Points to Dockerfile for containerization

2. **Dockerfile** - Multi-stage Docker build
   - Build stage: Compiles Java application with Maven
   - Production stage: Lightweight JRE-based runtime image
   - Exposes port 8080 for the application

3. **.dockerignore** - Optimizes Docker builds
   - Excludes unnecessary files from Docker context

### Infrastructure as Code (Bicep)

#### Main Templates
1. **infra/main.bicep** - Orchestration template
   - Defines all Azure resources
   - Manages resource dependencies
   - Configures environment variables and secrets

2. **infra/abbreviations.json** - Resource naming conventions
   - Standardizes Azure resource prefixes

3. **infra/main.parameters.json** - Parameter definitions
   - Environment-specific configurations

#### Core Modules

1. **infra/core/host/container-app.bicep**
   - Container App configuration
   - Ingress settings
   - Scaling configuration
   - Environment variables and secrets

2. **infra/core/host/container-registry.bicep**
   - Container Registry setup
   - Admin user configuration
   - SKU selection

3. **infra/core/host/container-apps-environment.bicep**
   - Managed environment for containers
   - Networking configuration

4. **infra/core/host/container-registry-access.bicep**
   - RBAC role assignments
   - ACR pull permissions

5. **infra/core/database/postgresql/flexibleserver.bicep**
   - PostgreSQL Flexible Server
   - Database creation
   - Firewall rules
   - Backup configuration

### Documentation

1. **AZURE_DEPLOYMENT.md** - Detailed deployment guide
   - Prerequisites
   - Step-by-step instructions
   - Troubleshooting tips
   - Monitoring guidance

2. **deploy-to-azure.sh** - Automated deployment script
   - Interactive deployment workflow
   - Prerequisite checks
   - Environment setup
   - Resource provisioning
   - Application deployment

## Deployment Workflow

### Phase 1: Prerequisites
```bash
# Install required tools
- Azure CLI (az)
- Azure Developer CLI (azd)
- Docker
```

### Phase 2: Authentication
```bash
# Login to Azure
azd auth login
az login
```

### Phase 3: Environment Setup
```bash
# Create a new environment
azd env new <environment-name> --location <azure-region>

# Set required variables
azd env set POSTGRES_ADMIN_PASSWORD '<secure-password>'
```

### Phase 4: Provision Infrastructure
```bash
# Deploy Bicep templates to Azure
azd provision
```

This creates:
- Resource Group with naming convention: `rg-<environment>`
- Container Registry: `cr<unique-hash>`
- Container Apps Environment: `cae-<unique-hash>`
- PostgreSQL Server: `psql-<unique-hash>`
- Container App: `ca-web-<unique-hash>`

### Phase 5: Deploy Application
```bash
# Build and deploy the application
azd deploy
```

This performs:
1. Builds Docker image locally
2. Pushes image to Azure Container Registry
3. Updates Container App with new image
4. Container App pulls image and starts the application

### Phase 6: Verification
```bash
# Get application URL
azd env get-values | grep WEB_URI

# View logs
azd logs

# Check health
curl https://<app-url>/actuator/health
```

## Application Configuration

### Environment Variables
The following environment variables are configured in the Container App:

- `SPRING_PROFILES_ACTIVE=postgres` - Activates PostgreSQL profile
- `SPRING_DATASOURCE_URL` - JDBC connection string
- `SPRING_DATASOURCE_USERNAME` - Database username
- `SPRING_DATASOURCE_PASSWORD` - Database password (stored as secret)

### Database Schema
The application automatically initializes the database schema on first startup using Spring Boot's schema initialization feature.

## Resource Specifications

### Container App
- **CPU**: 1.0 cores
- **Memory**: 2.0 GiB
- **Min Replicas**: 1
- **Max Replicas**: 10
- **Port**: 8080

### PostgreSQL Database
- **Version**: 16
- **Tier**: Burstable
- **SKU**: Standard_B1ms
- **Storage**: 32 GB
- **Backup Retention**: 7 days

### Container Registry
- **SKU**: Basic
- **Admin User**: Enabled

## Cost Considerations

Estimated monthly costs (subject to change):
- Container Apps: ~$15-30 (depends on usage)
- PostgreSQL Flexible Server (Burstable): ~$15-20
- Container Registry (Basic): ~$5
- Storage and networking: ~$5-10

**Total estimated cost**: ~$40-65/month

## Security Features

1. **Database Security**
   - SSL/TLS required for connections
   - Firewall rules restricting access
   - Password stored as Container App secret

2. **Container Security**
   - Images stored in private registry
   - Managed identity for ACR access
   - HTTPS-only ingress

3. **Network Security**
   - Azure-managed networking
   - Container Apps environment isolation

## Monitoring and Operations

### Health Checks
- Spring Boot Actuator endpoints enabled
- Health endpoint: `/actuator/health`
- Info endpoint: `/actuator/info`

### Logging
```bash
# View application logs
azd logs

# View specific container logs in Azure Portal
# Navigate to Container App -> Log stream
```

### Scaling
- Auto-scaling based on HTTP traffic
- Min 1 replica, Max 10 replicas
- Can be adjusted in `infra/main.bicep`

## Cleanup

To delete all Azure resources:
```bash
azd down
```

This removes:
- All deployed resources
- Resource group
- Environment configuration (locally)

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Ensure Docker is running
   - Check internet connectivity
   - Verify Maven can download dependencies

2. **Deployment Failures**
   - Check Azure subscription permissions
   - Verify resource quotas
   - Review deployment logs with `azd logs`

3. **Database Connection Issues**
   - Verify firewall rules allow Azure services
   - Check connection string format
   - Ensure PostgreSQL is running

### Debug Commands
```bash
# Check environment variables
azd env get-values

# View detailed logs
azd logs --follow

# Check resource status in Azure Portal
az resource list --resource-group rg-<environment>
```

## Next Steps

After successful deployment:

1. **Configure Custom Domain** (optional)
   - Add custom domain in Azure Portal
   - Configure DNS records
   - Add SSL certificate

2. **Setup CI/CD** (optional)
   - Integrate with GitHub Actions
   - Use azd hooks for automated deployments

3. **Enable Advanced Monitoring** (optional)
   - Configure Application Insights
   - Set up alerts
   - Create dashboards

4. **Scale as Needed**
   - Adjust replica counts
   - Upgrade database tier
   - Enable zone redundancy

## Support and Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Spring PetClinic GitHub Repository](https://github.com/spring-projects/spring-petclinic)

---

**Document Version**: 1.0  
**Last Updated**: January 2026  
**Deployment Tool**: Azure Developer CLI (azd) v1.22.5  
**IaC Type**: Bicep  
**Hosting**: Azure Container Apps (non-AKS)
