# Scripts

This directory contains utility scripts for the Spring PetClinic application.

## azure-postgresql-recommend.sh

A recommendation script that helps you choose the optimal Azure region and SKU for deploying Azure Database for PostgreSQL Flexible Server.

### Usage

```bash
./scripts/azure-postgresql-recommend.sh
```

### Prerequisites

- Azure CLI installed (`az` command)
- Logged in to Azure (`az login`)
- Valid Azure subscription

### What It Does

The script provides:
- Available Azure regions with quota information
- Recommended SKUs for different tiers (Burstable, General Purpose, Memory Optimized)
- Specific recommendations for Spring PetClinic deployment
- Cost estimates
- Sample Azure CLI deployment commands

### Environment Variables

- `AZURE_SUBSCRIPTION_ID`: Override the default subscription ID (optional)

### Example Output

The script displays:
1. Available regions with quota
2. SKU options by tier
3. Specific recommendations for PetClinic (dev and prod)
4. Sample deployment commands

For detailed information, see [Azure PostgreSQL Recommendations](../docs/AZURE_POSTGRESQL_RECOMMENDATIONS.md).
