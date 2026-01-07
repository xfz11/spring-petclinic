#!/bin/bash

# Script to get region and SKU recommendations for PostgreSQL deployment
# This script demonstrates using the appmod-get-available-region-sku tool

set -e

echo "=================================================="
echo "PostgreSQL Region and SKU Recommendation Tool"
echo "=================================================="
echo ""

# Check if subscription ID is provided
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "Error: AZURE_SUBSCRIPTION_ID environment variable is not set"
    echo "Usage: export AZURE_SUBSCRIPTION_ID=<your-subscription-id>"
    echo "       ./get-postgres-recommendations.sh"
    exit 1
fi

echo "Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo ""
echo "Analyzing available regions and SKUs for PostgreSQL..."
echo ""

# Resource configuration
RESOURCE_TYPE="Microsoft.DBforPostgreSQL/flexibleServers"
QUOTA=1
WORKSPACE_FOLDER=$(pwd)

echo "Configuration:"
echo "  Resource Type: $RESOURCE_TYPE"
echo "  Quota Required: $QUOTA"
echo "  Workspace: $WORKSPACE_FOLDER"
echo ""

# The appmod-get-available-region-sku tool should be called here
# In a real implementation, this would invoke the MCP tool
# For demonstration purposes, we show the expected parameters

cat << EOF
Tool Parameters:
{
  "subscriptionId": "$AZURE_SUBSCRIPTION_ID",
  "resourceTypes": [
    {
      "type": "$RESOURCE_TYPE",
      "quota": $QUOTA
    }
  ],
  "preferredRegions": [],
  "workspaceFolder": "$WORKSPACE_FOLDER"
}
EOF

echo ""
echo "=================================================="
echo "Expected Output:"
echo "=================================================="
echo "The tool will return recommendations including:"
echo "  - Available Azure regions for PostgreSQL deployment"
echo "  - Supported SKUs in each region"
echo "  - Quota availability status"
echo ""
echo "Example regions that typically support PostgreSQL:"
echo "  - East US"
echo "  - East US 2"
echo "  - West US"
echo "  - West US 2"
echo "  - Central US"
echo "  - North Europe"
echo "  - West Europe"
echo ""
echo "Common PostgreSQL Flexible Server SKUs:"
echo "  Burstable Tier:"
echo "    - B1ms (1 vCore, 2 GiB RAM)"
echo "    - B2s (2 vCores, 4 GiB RAM)"
echo "  General Purpose Tier:"
echo "    - D2ds_v4 (2 vCores, 8 GiB RAM)"
echo "    - D4ds_v4 (4 vCores, 16 GiB RAM)"
echo "    - D8ds_v4 (8 vCores, 32 GiB RAM)"
echo "  Memory Optimized Tier:"
echo "    - E2ds_v4 (2 vCores, 16 GiB RAM)"
echo "    - E4ds_v4 (4 vCores, 32 GiB RAM)"
echo ""
echo "For Spring PetClinic development: B1ms or B2s"
echo "For Spring PetClinic production: D2ds_v4 or D4ds_v4"
echo "=================================================="
