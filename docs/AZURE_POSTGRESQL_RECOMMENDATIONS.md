# Azure PostgreSQL Region and SKU Recommendations

This document provides guidance on selecting the optimal Azure region and SKU for deploying Azure Database for PostgreSQL Flexible Server for the Spring PetClinic application.

## Quick Start

Run the recommendation script:

```bash
./scripts/azure-postgresql-recommend.sh
```

## Available Regions

Based on current quota availability, the following regions are recommended:

### 1. Southeast Asia (southeastasia)
- **Available quota:** 24 cores
- **Latency:** Good for Asia-Pacific users
- **Tier options:** Burstable, General Purpose, Memory Optimized

### 2. West US 3 (westus3)
- **Available quota:** 23 cores
- **Latency:** Optimal for US West Coast
- **Tier options:** Burstable, General Purpose, Memory Optimized

### 3. Sweden Central (swedencentral)
- **Available quota:** 18 cores
- **Latency:** Best for European users
- **Tier options:** Burstable, General Purpose, Memory Optimized

### 4. West Central US (westcentralus)
- **Available quota:** 24 cores
- **Latency:** Good for central US
- **Tier options:** Burstable, General Purpose, Memory Optimized

## SKU Recommendations

### For Development/Testing (Burstable Tier)

Best for non-production workloads with variable CPU usage:

| SKU | vCores | RAM | Use Case |
|-----|--------|-----|----------|
| Standard_B1ms | 1 | 2 GiB | Minimal dev/test |
| Standard_B2s | 2 | 4 GiB | **Recommended for PetClinic dev** |
| Standard_B2ms | 2 | 8 GiB | Dev with more memory |

**Cost:** $13-52/month

### For Production (General Purpose Tier)

Balanced compute and memory for most production workloads:

| SKU | vCores | RAM | Use Case |
|-----|--------|-----|----------|
| Standard_D2s_v3 | 2 | 8 GiB | Small production |
| Standard_D2ds_v4 | 2 | 8 GiB | **Recommended for PetClinic prod** |
| Standard_D2ads_v5 | 2 | 8 GiB | Latest generation |
| Standard_D4s_v3 | 4 | 16 GiB | Medium production |
| Standard_D4ds_v4 | 4 | 16 GiB | Medium with better performance |
| Standard_D4ads_v5 | 4 | 16 GiB | Latest generation, medium |

**Cost:** $150-600/month

### For Memory-Intensive Workloads (Memory Optimized Tier)

Higher memory-to-vCore ratio for database-heavy applications:

| SKU | vCores | RAM | Use Case |
|-----|--------|-----|----------|
| Standard_E2s_v3 | 2 | 16 GiB | Memory-intensive, small |
| Standard_E2ds_v4 | 2 | 16 GiB | Latest gen, memory-intensive |
| Standard_E2ads_v5 | 2 | 16 GiB | Latest gen, AMD |
| Standard_E4s_v3 | 4 | 32 GiB | Memory-intensive, medium |
| Standard_E4ds_v4 | 4 | 32 GiB | Latest gen, medium |
| Standard_E4ads_v5 | 4 | 32 GiB | Latest gen, AMD, medium |

**Cost:** $250-1000/month

## Recommended Configuration for PetClinic

### Development/Demo Environment

```bash
Region: southeastasia
SKU: Standard_B2s (Burstable)
vCores: 2
RAM: 4 GiB
Storage: 32 GB
Version: PostgreSQL 16
High Availability: Disabled
Estimated Cost: ~$25/month
```

### Production Environment

```bash
Region: southeastasia or westus3
SKU: Standard_D2ds_v4 (General Purpose)
vCores: 2
RAM: 8 GiB
Storage: 128 GB
Version: PostgreSQL 16
High Availability: Zone-redundant (Enabled)
Backup Retention: 7-35 days
Estimated Cost: ~$300-400/month
```

## Deployment Example

### Using Azure CLI

```bash
# Development Environment
az postgres flexible-server create \
  --name petclinic-db-dev \
  --resource-group petclinic-rg \
  --location southeastasia \
  --sku-name Standard_B2s \
  --tier Burstable \
  --storage-size 32 \
  --admin-user petclinic \
  --admin-password "YourSecurePassword123!" \
  --database-name petclinic \
  --public-access 0.0.0.0 \
  --version 16
```

```bash
# Production Environment with High Availability
az postgres flexible-server create \
  --name petclinic-db-prod \
  --resource-group petclinic-rg \
  --location southeastasia \
  --sku-name Standard_D2ds_v4 \
  --tier GeneralPurpose \
  --storage-size 128 \
  --admin-user petclinic \
  --admin-password "YourSecurePassword123!" \
  --database-name petclinic \
  --high-availability ZoneRedundant \
  --standby-zone 2 \
  --public-access 0.0.0.0 \
  --version 16 \
  --backup-retention 14
```

### Connection String

After deployment, configure your Spring Boot application with:

```properties
spring.datasource.url=jdbc:postgresql://<server-name>.postgres.database.azure.com:5432/petclinic?sslmode=require
spring.datasource.username=petclinic
spring.datasource.password=<your-password>
spring.profiles.active=postgres
```

## Region Selection Criteria

Consider the following factors when choosing a region:

1. **Proximity to Users:** Select a region closest to your user base for lower latency
2. **Quota Availability:** Choose regions with sufficient quota (cores available)
3. **Compliance:** Ensure the region meets data residency requirements
4. **Cost:** Pricing varies slightly by region
5. **Availability Zones:** Prefer regions with multiple availability zones for HA

## SKU Selection Criteria

1. **Workload Type:**
   - Variable, low usage → Burstable
   - Consistent, moderate usage → General Purpose
   - Database-heavy, high memory → Memory Optimized

2. **Spring PetClinic Requirements:**
   - Simple demo application
   - Low to moderate concurrent users (< 50)
   - Small database size (< 1 GB)
   - **Recommendation:** Start with Burstable (B2s) for dev, General Purpose (D2ds_v4) for prod

3. **Scalability:** All tiers support scaling up/down without downtime

## Cost Optimization Tips

1. **Start Small:** Begin with Burstable tier and scale up based on actual usage
2. **Reserved Capacity:** Save up to 65% with 1-year or 3-year reserved instances
3. **Stop/Start:** Stop non-production databases when not in use
4. **Storage:** Start with minimum required storage; it can be increased but not decreased
5. **Backup Retention:** Keep 7 days for dev, 14-35 days for production

## Monitoring and Scaling

Monitor these metrics to determine if scaling is needed:

- **CPU Utilization:** Scale up if consistently > 80%
- **Memory Usage:** Scale up if consistently > 85%
- **IOPS:** Increase storage if IOPS are throttled
- **Connection Count:** Scale up if approaching max connections

## Additional Resources

- [Azure Database for PostgreSQL Pricing](https://azure.microsoft.com/pricing/details/postgresql/)
- [Azure Database for PostgreSQL Documentation](https://docs.microsoft.com/azure/postgresql/)
- [Spring Boot PostgreSQL Configuration](https://docs.spring.io/spring-boot/docs/current/reference/html/data.html#data.sql.datasource)

## Support

For issues or questions:
- Azure Support: [Azure Portal Support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)
- Spring PetClinic: [GitHub Issues](https://github.com/spring-projects/spring-petclinic/issues)
