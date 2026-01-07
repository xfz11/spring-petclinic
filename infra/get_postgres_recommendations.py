"""
Script to get PostgreSQL region and SKU recommendations using Azure AppMod tool.

This script demonstrates how to use the appmod-get-available-region-sku tool
to find optimal regions and SKUs for deploying PostgreSQL for Spring PetClinic.
"""

import json
import os
import sys


def get_postgres_recommendations(subscription_id, workspace_folder, preferred_regions=None):
    """
    Get region and SKU recommendations for PostgreSQL deployment.
    
    Args:
        subscription_id (str): Azure subscription ID
        workspace_folder (str): Path to the workspace folder
        preferred_regions (list): Optional list of preferred regions
    
    Returns:
        dict: Recommendations including available regions and SKUs
    """
    if preferred_regions is None:
        preferred_regions = []
    
    # Configuration for PostgreSQL Flexible Server
    config = {
        "subscriptionId": subscription_id,
        "resourceTypes": [
            {
                "type": "Microsoft.DBforPostgreSQL/flexibleServers",
                "quota": 1
            }
        ],
        "preferredRegions": preferred_regions,
        "workspaceFolder": workspace_folder
    }
    
    return config


def print_recommendations():
    """Print PostgreSQL deployment recommendations."""
    print("=" * 60)
    print("PostgreSQL Region and SKU Recommendations")
    print("=" * 60)
    print()
    
    # Get configuration
    subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID', 'YOUR_SUBSCRIPTION_ID')
    workspace_folder = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    config = get_postgres_recommendations(subscription_id, workspace_folder)
    
    print("Tool Configuration:")
    print(json.dumps(config, indent=2))
    print()
    
    print("Resource Details:")
    print("  Type: PostgreSQL Flexible Server")
    print("  Service: Microsoft.DBforPostgreSQL/flexibleServers")
    print("  Quota: 1 instance")
    print()
    
    print("Recommended Regions (typical availability):")
    regions = [
        "East US",
        "East US 2",
        "West US 2",
        "West US 3",
        "Central US",
        "North Europe",
        "West Europe",
        "UK South",
        "Southeast Asia",
        "Australia East"
    ]
    for region in regions:
        print(f"  - {region}")
    print()
    
    print("Recommended SKUs by Use Case:")
    print()
    print("  Development/Testing (Burstable):")
    print("    - B1ms: 1 vCore, 2 GiB RAM, ~$12/month")
    print("    - B2s: 2 vCores, 4 GiB RAM, ~$24/month")
    print()
    print("  Production (General Purpose):")
    print("    - D2ds_v4: 2 vCores, 8 GiB RAM")
    print("    - D4ds_v4: 4 vCores, 16 GiB RAM")
    print("    - D8ds_v4: 8 vCores, 32 GiB RAM")
    print()
    print("  High-Performance (Memory Optimized):")
    print("    - E2ds_v4: 2 vCores, 16 GiB RAM")
    print("    - E4ds_v4: 4 vCores, 32 GiB RAM")
    print()
    
    print("Recommendation for Spring PetClinic:")
    print("  Development: B1ms or B2s in any available region")
    print("  Production: D2ds_v4 or D4ds_v4 in region closest to users")
    print()
    
    print("=" * 60)
    print("Note: Run the appmod-get-available-region-sku tool to get")
    print("real-time availability for your specific subscription.")
    print("=" * 60)


if __name__ == "__main__":
    print_recommendations()
