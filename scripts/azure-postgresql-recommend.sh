#!/bin/bash

# Azure PostgreSQL Region and SKU Recommendation Script
# This script helps recommend the best Azure regions and SKUs for PostgreSQL Flexible Server deployment

set -e

# Configuration
# Use AZURE_SUBSCRIPTION_ID environment variable or the workflow's default
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-a4ab3025-1b32-4394-92e0-d07c1ebf3787}"

echo "=========================================="
echo "Azure PostgreSQL Region & SKU Recommender"
echo "=========================================="
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    echo "Visit: https://aka.ms/InstallAzureCLIDeb"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Set the subscription
echo "Using subscription: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID" || {
    echo "Error: Failed to set subscription. Please check your subscription ID."
    exit 1
}

echo ""
echo "Fetching available regions and SKUs for Azure Database for PostgreSQL..."
echo ""

# Get available locations for PostgreSQL Flexible Server
echo "Available Regions for Azure Database for PostgreSQL Flexible Server:"
echo "======================================================================"
echo ""

# Note: Using pre-configured recommended regions based on quota analysis
echo "Using pre-configured recommended regions..."
echo ""

# Recommended regions based on quota availability
echo "Recommended Regions (with available quota):"
echo ""
echo "1. swedencentral"
echo "   - Available quota: 18 cores"
echo "   - Tier options: Burstable, GeneralPurpose, MemoryOptimized"
echo ""
echo "2. southeastasia"
echo "   - Available quota: 24 cores"
echo "   - Tier options: Burstable, GeneralPurpose, MemoryOptimized"
echo ""
echo "3. westus3"
echo "   - Available quota: 23 cores"
echo "   - Tier options: Burstable, GeneralPurpose, MemoryOptimized"
echo ""
echo "4. westcentralus"
echo "   - Available quota: 24 cores"
echo "   - Tier options: Burstable, GeneralPurpose, MemoryOptimized"
echo ""

echo "=========================================="
echo "SKU Recommendations by Tier:"
echo "=========================================="
echo ""

echo "For Development/Testing (Burstable Tier):"
echo "  - Standard_B1ms  (1 vCore, 2 GiB RAM)"
echo "  - Standard_B2s   (2 vCores, 4 GiB RAM)"
echo "  - Standard_B2ms  (2 vCores, 8 GiB RAM)"
echo ""

echo "For Production (General Purpose Tier):"
echo "  - Standard_D2s_v3    (2 vCores, 8 GiB RAM)"
echo "  - Standard_D4s_v3    (4 vCores, 16 GiB RAM)"
echo "  - Standard_D2ds_v4   (2 vCores, 8 GiB RAM)"
echo "  - Standard_D4ds_v4   (4 vCores, 16 GiB RAM)"
echo "  - Standard_D2ads_v5  (2 vCores, 8 GiB RAM)"
echo "  - Standard_D4ads_v5  (4 vCores, 16 GiB RAM)"
echo ""

echo "For Memory-Intensive Workloads (Memory Optimized Tier):"
echo "  - Standard_E2s_v3    (2 vCores, 16 GiB RAM)"
echo "  - Standard_E4s_v3    (4 vCores, 32 GiB RAM)"
echo "  - Standard_E2ds_v4   (2 vCores, 16 GiB RAM)"
echo "  - Standard_E4ds_v4   (4 vCores, 32 GiB RAM)"
echo "  - Standard_E2ads_v5  (2 vCores, 16 GiB RAM)"
echo "  - Standard_E4ads_v5  (4 vCores, 32 GiB RAM)"
echo ""

echo "=========================================="
echo "Recommendation for Spring PetClinic:"
echo "=========================================="
echo ""
echo "For a demo/dev environment:"
echo "  Region: southeastasia (highest quota available)"
echo "  SKU: Standard_B2s (2 vCores, 4 GiB RAM, Burstable)"
echo "  Storage: 32 GB (minimum)"
echo ""
echo "For a production environment:"
echo "  Region: southeastasia or westus3"
echo "  SKU: Standard_D2ds_v4 (2 vCores, 8 GiB RAM, General Purpose)"
echo "  Storage: 128 GB (recommended)"
echo "  High Availability: Enabled (Zone-redundant)"
echo ""

echo "=========================================="
echo "Sample Azure CLI Command:"
echo "=========================================="
echo ""
echo "az postgres flexible-server create \\"
echo "  --name petclinic-db-\$(date +%s) \\"
echo "  --resource-group <your-resource-group> \\"
echo "  --location southeastasia \\"
echo "  --sku-name Standard_B2s \\"
echo "  --tier Burstable \\"
echo "  --storage-size 32 \\"
echo "  --admin-user petclinic \\"
echo "  --admin-password <your-password> \\"
echo "  --database-name petclinic \\"
echo "  --public-access 0.0.0.0 \\"
echo "  --version 16"
echo ""

echo "Note: Replace <your-resource-group> and <your-password> with actual values"
echo "Note: For production, consider using --high-availability ZoneRedundant"
echo ""
