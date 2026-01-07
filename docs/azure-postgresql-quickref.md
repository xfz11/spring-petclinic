# Azure PostgreSQL Quick Reference

## Recommended Configuration for Spring PetClinic

### For Development/Testing

**Region**: East US 2 (or closest to you)
**SKU**: Burstable B1ms
- 1 vCore, 2 GiB RAM
- 32 GB storage
- ~$15-20/month

**Command**:
```bash
az postgres flexible-server create \
  --name petclinic-dev-postgres \
  --resource-group petclinic-rg \
  --location eastus2 \
  --tier Burstable \
  --sku-name Standard_B1ms \
  --storage-size 32 \
  --version 16 \
  --admin-user petclinic \
  --admin-password <your-password>
```

### For Production

**Region**: East US 2 (or closest to you)
**SKU**: General Purpose D2ds_v4
- 2 vCores, 8 GiB RAM
- 128 GB storage
- High Availability enabled
- ~$280-350/month (includes HA)

**Command**:
```bash
az postgres flexible-server create \
  --name petclinic-prod-postgres \
  --resource-group petclinic-rg \
  --location eastus2 \
  --tier GeneralPurpose \
  --sku-name Standard_D2ds_v4 \
  --storage-size 128 \
  --version 16 \
  --admin-user petclinic \
  --admin-password <your-password> \
  --high-availability ZoneRedundant \
  --backup-retention 30
```

### Application Configuration

**Environment Variables**:
```bash
export POSTGRES_URL="jdbc:postgresql://<server-name>.postgres.database.azure.com:5432/petclinic?sslmode=require"
export POSTGRES_USER="petclinic"
export POSTGRES_PASS="<your-password>"
```

**Run with PostgreSQL profile**:
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=postgres
```

## Top Regions by Geographic Location

| Location | Primary Region | Alternative |
|----------|---------------|-------------|
| North America East | East US 2 | East US |
| North America West | West US 2 | West US 3 |
| Europe | West Europe | North Europe |
| Asia Pacific | Southeast Asia | East Asia |
| Australia | Australia East | Australia Southeast |
| Brazil | Brazil South | - |
| Japan | Japan East | Japan West |
| UK | UK South | UK West |
| Canada | Canada Central | Canada East |
| India | Central India | South India |

## SKU Comparison Table

| Tier | SKU | vCores | Memory | Use Case | ~Cost/Month |
|------|-----|--------|--------|----------|-------------|
| Burstable | B1ms | 1 | 2 GiB | Dev/Test | $15-20 |
| Burstable | B2s | 2 | 4 GiB | Small apps | $35-45 |
| General Purpose | D2ds_v4 | 2 | 8 GiB | Production | $140-180 |
| General Purpose | D4ds_v4 | 4 | 16 GiB | High traffic | $280-350 |
| General Purpose | D8ds_v4 | 8 | 32 GiB | Enterprise | $560-700 |

*Note: Costs are approximate and vary by region. Add ~100% for High Availability.*

## Common Commands

### Create Database
```bash
az postgres flexible-server db create \
  --resource-group petclinic-rg \
  --server-name <server-name> \
  --database-name petclinic
```

### Configure Firewall
```bash
# Allow your IP
az postgres flexible-server firewall-rule create \
  --resource-group petclinic-rg \
  --name <server-name> \
  --rule-name AllowMyIP \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>
```

### Connect with psql
```bash
psql "host=<server-name>.postgres.database.azure.com port=5432 dbname=petclinic user=petclinic password=<password> sslmode=require"
```

### Get Connection String
```bash
az postgres flexible-server show-connection-string \
  --server-name <server-name> \
  --database-name petclinic \
  --admin-user petclinic
```

## See Full Documentation

For detailed information, see [Azure PostgreSQL Deployment Guide](azure-postgresql-deployment.md)
