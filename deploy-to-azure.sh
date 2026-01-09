#!/bin/bash
# Azure Deployment Script for Spring PetClinic
# This script demonstrates the full deployment workflow using Azure Developer CLI (azd)

set -e

echo "=========================================="
echo "Azure Deployment Script for Spring PetClinic"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v azd &> /dev/null; then
    echo "Error: Azure Developer CLI (azd) is not installed."
    echo "Please install it from: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd"
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI (az) is not installed."
    echo "Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Please install it from: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✓ All prerequisites are installed"
echo ""

# Login to Azure
echo "Step 1: Logging in to Azure..."
echo "You will be prompted to authenticate in your browser."
azd auth login
az login

echo ""
echo "Step 2: Initializing Azure environment..."
echo "Please enter a name for your environment (e.g., petclinic-dev)"
read -p "Environment name: " ENV_NAME

if [ -z "$ENV_NAME" ]; then
    ENV_NAME="petclinic-dev"
    echo "Using default environment name: $ENV_NAME"
fi

echo ""
echo "Please enter your preferred Azure location (e.g., eastus, westus2)"
read -p "Azure location [eastus]: " LOCATION

if [ -z "$LOCATION" ]; then
    LOCATION="eastus"
fi

# Initialize azd
azd env new "$ENV_NAME" --location "$LOCATION"

echo ""
echo "Step 3: Setting environment variables..."

# Generate a secure password for PostgreSQL
POSTGRES_PASSWORD=$(openssl rand -base64 16)
echo "Generated secure PostgreSQL password"

# Set environment variables
azd env set POSTGRES_ADMIN_PASSWORD "$POSTGRES_PASSWORD"

echo "✓ Environment variables configured"
echo ""

echo "Step 4: Provisioning Azure resources..."
echo "This will create the following resources in Azure:"
echo "  - Resource Group"
echo "  - Container Registry"
echo "  - Container Apps Environment"
echo "  - PostgreSQL Flexible Server"
echo "  - Container App for web service"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

azd provision

echo ""
echo "✓ Azure resources provisioned successfully"
echo ""

echo "Step 5: Deploying the application..."
echo "This will build the Docker image and deploy it to Azure Container Apps"
read -p "Press Enter to continue or Ctrl+C to cancel..."

azd deploy

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""

# Get the application URL
WEB_URI=$(azd env get-values | grep WEB_URI | cut -d'=' -f2 | tr -d '"')

echo "Your Spring PetClinic application is now running on Azure!"
echo ""
echo "Application URL: $WEB_URI"
echo ""
echo "You can also view the following endpoints:"
echo "  - Health check: $WEB_URI/actuator/health"
echo "  - Application info: $WEB_URI/actuator/info"
echo ""
echo "To view logs:"
echo "  azd logs"
echo ""
echo "To clean up resources:"
echo "  azd down"
echo ""
