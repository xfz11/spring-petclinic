# Azure PostgreSQL Deployment Guide for Spring PetClinic

This guide provides recommendations for deploying Azure Database for PostgreSQL Flexible Server for the Spring PetClinic application.

## Recommended Regions

### Primary Recommendations (Global)

For optimal performance and availability, consider these regions based on your geographic location:

#### North America
- **East US 2** (Virginia) - Recommended
  - High availability zones
  - Cost-effective
  - Latest features available
  - Good connectivity

- **West US 2** (Washington) - Alternative
  - Availability zones
  - Good for West Coast users

#### Europe
- **West Europe** (Netherlands) - Recommended
  - High availability
  - Cost-effective for European users
  - GDPR compliant

- **North Europe** (Ireland) - Alternative
  - Good connectivity
  - Availability zones

#### Asia Pacific
- **Southeast Asia** (Singapore) - Recommended
  - Good connectivity across Asia
  - Availability zones

- **East Asia** (Hong Kong) - Alternative
  - Good for China region access

### Region Selection Criteria

When choosing a region, consider:
1. **Proximity to users** - Lower latency
2. **Availability zones** - Higher availability (3+ zones recommended)
3. **Compliance requirements** - Data residency, GDPR, etc.
4. **Cost** - Varies by region (typically 10-30% difference)
5. **Feature availability** - Newer features may be region-specific

## Recommended SKUs

Azure Database for PostgreSQL Flexible Server offers various SKUs. Here are recommendations based on workload:

### Development/Testing Environment

**SKU: Burstable B1ms**
- **vCores**: 1
- **Memory**: 2 GiB
- **Storage**: 32 GB (can scale up to 16 TB)
- **IOPS**: 640 baseline, up to 3,500 burstable
- **Cost**: ~$14-20/month (varies by region)
- **Use case**: Development, testing, low-traffic applications

```bash
# Azure CLI example
az postgres flexible-server create \
  --name petclinic-dev-postgres \
  --resource-group petclinic-rg \
  --location eastus2 \
  --tier Burstable \
  --sku-name Standard_B1ms \
  --storage-size 32 \
  --version 16 \
  --admin-user petclinic \
  --admin-password <your-secure-password> \
  --public-access 0.0.0.0
```

### Production Environment (Small to Medium)

**SKU: General Purpose D2ds_v4**
- **vCores**: 2
- **Memory**: 8 GiB
- **Storage**: 128 GB (recommended)
- **IOPS**: 3,100 baseline, up to 5,000 with scaling
- **Cost**: ~$140-180/month (varies by region)
- **Use case**: Production workloads with moderate traffic

```bash
# Azure CLI example
az postgres flexible-server create \
  --name petclinic-prod-postgres \
  --resource-group petclinic-rg \
  --location eastus2 \
  --tier GeneralPurpose \
  --sku-name Standard_D2ds_v4 \
  --storage-size 128 \
  --version 16 \
  --admin-user petclinic \
  --admin-password <your-secure-password> \
  --high-availability ZoneRedundant \
  --backup-retention 7
```

### Production Environment (High Performance)

**SKU: General Purpose D4ds_v4**
- **vCores**: 4
- **Memory**: 16 GiB
- **Storage**: 256 GB (recommended)
- **IOPS**: 6,400 baseline, up to 10,000 with scaling
- **Cost**: ~$280-350/month (varies by region)
- **Use case**: High-traffic production workloads

```bash
# Azure CLI example
az postgres flexible-server create \
  --name petclinic-prod-postgres \
  --resource-group petclinic-rg \
  --location eastus2 \
  --tier GeneralPurpose \
  --sku-name Standard_D4ds_v4 \
  --storage-size 256 \
  --version 16 \
  --admin-user petclinic \
  --admin-password <your-secure-password> \
  --high-availability ZoneRedundant \
  --backup-retention 30
```

## Spring PetClinic Specific Recommendations

Based on the Spring PetClinic application requirements:

### Database Version
- **PostgreSQL 16** (latest stable) - Recommended
- **PostgreSQL 15** - Also supported
- **PostgreSQL 14** - Supported but consider upgrading

### Storage Recommendations
- **Development**: 32 GB (minimum)
- **Production**: 128-256 GB (with auto-grow enabled)
- **Storage autogrow**: Enable to prevent out-of-space issues

### High Availability
- **Development**: Not required (single zone)
- **Production**: Zone-redundant high availability recommended
  - Provides automatic failover
  - 99.99% SLA
  - Zero data loss

### Backup Configuration
- **Development**: 7 days retention
- **Production**: 30 days retention
- Enable geo-redundant backup for critical production workloads

## Connection Configuration

### Application Properties

Update your `application-postgres.properties` or set environment variables:

```properties
# Azure PostgreSQL Flexible Server connection
spring.datasource.url=jdbc:postgresql://<server-name>.postgres.database.azure.com:5432/petclinic?sslmode=require
spring.datasource.username=petclinic
spring.datasource.password=${POSTGRES_PASS}

# Azure PostgreSQL recommended settings
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=20000
```

### Environment Variables

```bash
export POSTGRES_URL="jdbc:postgresql://<server-name>.postgres.database.azure.com:5432/petclinic?sslmode=require"
export POSTGRES_USER="petclinic"
export POSTGRES_PASS="<your-secure-password>"
```

### Firewall Rules

```bash
# Allow specific IP
az postgres flexible-server firewall-rule create \
  --resource-group petclinic-rg \
  --name petclinic-prod-postgres \
  --rule-name AllowMyIP \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>

# Allow Azure services
az postgres flexible-server firewall-rule create \
  --resource-group petclinic-rg \
  --name petclinic-prod-postgres \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

## Security Best Practices

1. **Use SSL/TLS**: Always enable SSL connections (sslmode=require)
2. **Private networking**: Use VNet integration for production
3. **Azure AD authentication**: Consider using managed identities
4. **Firewall rules**: Restrict access to known IP ranges
5. **Encryption**: Enable encryption at rest (enabled by default)
6. **Monitoring**: Enable Azure Monitor and diagnostic logs

## Performance Optimization

### Connection Pooling
Spring Boot uses HikariCP by default. Recommended settings:

```properties
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=10
spring.datasource.hikari.idle-timeout=300000
spring.datasource.hikari.max-lifetime=1200000
spring.datasource.hikari.connection-timeout=30000
```

### Database Parameters

Consider these PostgreSQL parameters for better performance:

```bash
# Update server parameters
az postgres flexible-server parameter set \
  --resource-group petclinic-rg \
  --server-name petclinic-prod-postgres \
  --name max_connections --value 100

az postgres flexible-server parameter set \
  --resource-group petclinic-rg \
  --server-name petclinic-prod-postgres \
  --name shared_buffers --value 32768

az postgres flexible-server parameter set \
  --resource-group petclinic-rg \
  --server-name petclinic-prod-postgres \
  --name work_mem --value 16384
```

## Cost Optimization Tips

1. **Right-size SKU**: Start with Burstable tier for dev/test
2. **Reserved capacity**: Save up to 63% with 1 or 3-year reservations
3. **Storage**: Enable autogrow but monitor usage
4. **Stop/Start**: Stop development servers when not in use (up to 7 days)
5. **Backup retention**: Use 7 days for non-production environments

## Monitoring and Alerts

Set up these key metrics:

1. **CPU percentage** > 80% alert
2. **Memory percentage** > 80% alert
3. **Storage percentage** > 85% alert
4. **Connection count** approaching max_connections
5. **Failed connections** > 5 in 5 minutes

## Migration from Local PostgreSQL

If migrating from local PostgreSQL to Azure:

```bash
# Export local database
pg_dump -h localhost -U petclinic petclinic > petclinic_backup.sql

# Import to Azure
psql "host=<server-name>.postgres.database.azure.com port=5432 dbname=petclinic user=petclinic password=<password> sslmode=require" < petclinic_backup.sql
```

## Quick Start Recommendation

For most users getting started with Spring PetClinic on Azure:

**Region**: East US 2 (or closest to your location)
**SKU**: 
- Development: Burstable B1ms
- Production: General Purpose D2ds_v4 with Zone-redundant HA

**Total Monthly Cost Estimate**:
- Development: ~$15-20/month
- Production: ~$280-350/month (with HA)

## References

- [Azure Database for PostgreSQL Documentation](https://docs.microsoft.com/azure/postgresql/)
- [Flexible Server Pricing](https://azure.microsoft.com/pricing/details/postgresql/flexible-server/)
- [PostgreSQL Best Practices](https://docs.microsoft.com/azure/postgresql/flexible-server/concepts-best-practices)
- [Spring Boot PostgreSQL Integration](https://spring.io/guides/gs/accessing-data-postgresql/)
