# Infrastructure Setup for Spring PetClinic

## PostgreSQL Region and SKU Recommendations

This document describes how to use the Azure region and SKU recommendation tool to find the best deployment options for PostgreSQL.

### Using the Region and SKU Recommendation Tool

To get recommendations for deploying PostgreSQL for the Spring PetClinic application, use the `appmod-get-available-region-sku` tool with the following parameters:

```json
{
  "subscriptionId": "YOUR_SUBSCRIPTION_ID",
  "resourceTypes": [
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers",
      "quota": 1
    }
  ],
  "preferredRegions": [],
  "workspaceFolder": "/path/to/spring-petclinic"
}
```

### Resource Type Details

- **Resource Type**: `Microsoft.DBforPostgreSQL/flexibleServers`
- **Quota Required**: 1 instance
- **Purpose**: PostgreSQL database for Spring PetClinic application

### Recommended Regions

The tool will analyze your subscription and recommend available regions based on:
- Region availability
- Quota availability
- Service capacity

### Common PostgreSQL SKUs

For production deployments, consider the following SKU options:
- **Burstable**: B1ms, B2s (development/testing)
- **General Purpose**: D2ds_v4, D4ds_v4, D8ds_v4 (production)
- **Memory Optimized**: E2ds_v4, E4ds_v4 (high-performance production)

### Next Steps

1. Run the recommendation tool to get available regions
2. Choose a region based on your requirements (latency, compliance, etc.)
3. Select an appropriate SKU based on workload requirements
4. Deploy PostgreSQL using Bicep or Terraform templates
