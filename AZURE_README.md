# Azure Deployment - Quick Start

This directory contains a complete Azure deployment solution for the Spring PetClinic application.

## 🚀 Quick Deploy

The fastest way to deploy to Azure:

```bash
./deploy-to-azure.sh
```

This interactive script will guide you through the entire deployment process.

## 📋 What's Included

### Infrastructure as Code (Bicep)
- Complete Azure infrastructure templates in the `infra/` directory
- Azure Container Apps (non-AKS hosting)
- PostgreSQL Flexible Server for production database
- Azure Container Registry for Docker images

### Configuration Files
- `azure.yaml` - Azure Developer CLI configuration
- `Dockerfile` - Multi-stage Docker build for the application
- `.dockerignore` - Optimized Docker build context

### Documentation
- **DEPLOYMENT_PLAN.md** - Comprehensive deployment plan with architecture diagrams
- **AZURE_DEPLOYMENT.md** - Detailed technical deployment guide
- **deploy-to-azure.sh** - Automated deployment script

## 📦 Prerequisites

Before deploying, ensure you have:

1. [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) installed
2. [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) installed
3. [Docker](https://docs.docker.com/get-docker/) installed and running
4. An active Azure subscription

## 🔧 Manual Deployment Steps

If you prefer to deploy manually:

### 1. Login to Azure
```bash
azd auth login
az login
```

### 2. Initialize Environment
```bash
azd env new <your-environment-name>
```

### 3. Set Required Variables
```bash
azd env set POSTGRES_ADMIN_PASSWORD '<secure-password>'
```

### 4. Provision Infrastructure
```bash
azd provision
```

### 5. Deploy Application
```bash
azd deploy
```

### 6. Get Application URL
```bash
azd env get-values | grep WEB_URI
```

## 🏗️ Architecture

The deployment creates:

- **Azure Container Apps**: Hosts the Spring Boot application with auto-scaling
- **Azure Container Registry**: Private registry for Docker images
- **PostgreSQL Flexible Server**: Production-grade database
- **Resource Group**: Organized resource management

## 💰 Cost Estimate

Approximately **$40-65 USD/month** for:
- Container Apps: ~$15-30
- PostgreSQL (Burstable): ~$15-20
- Container Registry (Basic): ~$5
- Storage/Networking: ~$5-10

## 📚 Additional Documentation

- See **DEPLOYMENT_PLAN.md** for the complete deployment plan
- See **AZURE_DEPLOYMENT.md** for detailed technical information
- See **README.md** (root) for application information

## 🧹 Cleanup

To delete all Azure resources:

```bash
azd down
```

## 🐛 Troubleshooting

### Build Issues
- Ensure Docker is running
- Check internet connectivity for Maven downloads

### Deployment Issues
- Verify Azure subscription permissions
- Check resource quotas in your Azure subscription
- Review logs with `azd logs`

### Database Connection Issues
- Verify firewall rules allow Azure services
- Check the connection string in environment variables

## 📞 Support

For issues or questions:
1. Check the troubleshooting sections in DEPLOYMENT_PLAN.md
2. Review [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
3. Check [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)

## ✅ Deployment Checklist

- [ ] Prerequisites installed (azd, az, docker)
- [ ] Logged in to Azure
- [ ] Chose environment name and region
- [ ] Generated secure PostgreSQL password
- [ ] Ran provision successfully
- [ ] Deployed application
- [ ] Verified application is running
- [ ] Accessed application URL

---

**Ready to deploy?** Run `./deploy-to-azure.sh` to get started! 🎉
