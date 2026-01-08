# Azure Deployment Quick Reference

## Prerequisites Checklist
- [ ] Azure CLI installed (`az --version`)
- [ ] Azure Developer CLI installed (`azd version`)
- [ ] Java 17 installed (`java -version`)
- [ ] Active Azure subscription
- [ ] Logged into Azure (`az login`)

## Quick Deploy (5 Steps)

```bash
# 1. Create environment
azd env new dev --no-prompt

# 2. Set variables
azd env set AZURE_ENV_NAME dev
azd env set AZURE_LOCATION eastus2
azd env set MYSQL_ADMIN_PASSWORD "YourSecurePassword123!"

# 3. Create resource group
az group create --name rg-dev-spring-petclinic --location eastus2

# 4. Configure resource group
azd env set AZURE_RESOURCE_GROUP rg-dev-spring-petclinic

# 5. Deploy!
azd up --no-prompt
```

## Common Commands

### Deployment
```bash
azd up --no-prompt              # Provision + deploy
azd provision --no-prompt       # Provision only
azd deploy --no-prompt          # Deploy only
azd provision --preview         # Dry run
```

### Monitoring
```bash
azd monitor --overview          # View logs
azd env get-values              # View outputs
```

### Updates
```bash
azd deploy --no-prompt          # Deploy new version
azd provision --no-prompt       # Update infrastructure
```

### Cleanup
```bash
azd down --force --purge --no-prompt    # Delete everything
```

## Resources Created

| Resource | SKU | Purpose |
|----------|-----|---------|
| App Service | B2 Basic | Java 17 app hosting |
| MySQL Server | Standard_B1ms | Database |
| Key Vault | Standard | Secrets storage |
| App Insights | Pay-per-use | Monitoring |
| Log Analytics | Pay-per-use | Logs |
| Managed Identity | - | Authentication |

**Monthly Cost**: ~$70-80 USD (development tier)

## Environment Variables Required

```bash
AZURE_ENV_NAME=dev                          # Environment name
AZURE_LOCATION=eastus2                      # Azure region
MYSQL_ADMIN_PASSWORD=YourSecurePassword     # MySQL password
AZURE_RESOURCE_GROUP=rg-dev-spring-petclinic # Resource group
```

## Application URLs

After deployment:
```bash
# Get app URL
azd env get-values | grep APP_SERVICE_URL

# Access endpoints
https://<your-app>.azurewebsites.net/              # Home
https://<your-app>.azurewebsites.net/actuator/health  # Health
```

## Troubleshooting

### Build Fails
```bash
./mvnw clean package    # Test build locally
java -version           # Verify Java 17
```

### Deployment Fails
```bash
az bicep build --file infra/main.bicep    # Validate Bicep
azd env get-values                        # Check variables
```

### App Won't Start
```bash
az webapp log tail --name <app-name> --resource-group <rg-name>
```

### Database Issues
```bash
# Check firewall rules
az mysql flexible-server firewall-rule list \
  --name <server-name> --resource-group <rg-name>
```

## Files Reference

- **azure.yaml** - AZD configuration
- **infra/main.bicep** - Infrastructure code
- **infra/main.parameters.json** - Parameters
- **AZURE_DEPLOYMENT.md** - Full guide
- **infra/README.md** - Infrastructure docs
- **.azure/summary.copilot.md** - Deployment summary

## Security Features

✓ HTTPS only  
✓ SSL for MySQL  
✓ Managed Identity  
✓ Key Vault for secrets  
✓ RBAC for Key Vault  
✓ CORS restricted  
✓ Secure parameters  

## Support

- Full guide: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md)
- Infrastructure: [infra/README.md](./infra/README.md)
- Plan: [.azure/plan.copilot.md](./.azure/plan.copilot.md)
- Summary: [.azure/summary.copilot.md](./.azure/summary.copilot.md)
