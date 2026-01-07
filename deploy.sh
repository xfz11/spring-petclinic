#!/bin/bash

# Deploy Spring PetClinic to Azure Container Apps
# This script builds the Docker image, pushes it to Azure Container Registry,
# and deploys it to Azure Container Apps using Bicep

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it from https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    print_info "All prerequisites are met."
}

# Parse command line arguments
RESOURCE_GROUP=""
LOCATION="eastus"
APP_NAME="petclinic"
ENVIRONMENT="dev"

while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -n|--app-name)
            APP_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -g, --resource-group    Azure resource group name (required)"
            echo "  -l, --location          Azure location (default: eastus)"
            echo "  -n, --app-name          Application name (default: petclinic)"
            echo "  -e, --environment       Environment name (default: dev)"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 -g my-resource-group -l eastus -n petclinic -e prod"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$RESOURCE_GROUP" ]; then
    print_error "Resource group name is required. Use -g or --resource-group to specify it."
    exit 1
fi

print_info "Starting deployment with the following parameters:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  App Name: $APP_NAME"
echo "  Environment: $ENVIRONMENT"
echo ""

# Check prerequisites
check_prerequisites

# Check if logged in to Azure
print_info "Checking Azure CLI login status..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_info "Using subscription: $SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
print_info "Creating resource group if it doesn't exist..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
print_info "Resource group '$RESOURCE_GROUP' is ready."

# Deploy infrastructure first to get the registry
print_info "Deploying initial infrastructure to create Container Registry..."
DEPLOYMENT_NAME="petclinic-infra-$(date +%Y%m%d-%H%M%S)"

# First deployment without container image to create ACR
az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file ./infra/main.bicep \
    --parameters appName="$APP_NAME" \
    --parameters environmentName="$ENVIRONMENT" \
    --parameters containerImage="mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
    --output none

print_info "Infrastructure deployed successfully."

# Get the Container Registry details
ACR_NAME=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.outputs.containerRegistryName.value -o tsv)

if [ -z "$ACR_NAME" ] || [ "$ACR_NAME" == "null" ]; then
    print_error "Failed to get Container Registry name from deployment."
    exit 1
fi

ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer -o tsv)
print_info "Container Registry: $ACR_LOGIN_SERVER"

# Log in to Azure Container Registry
print_info "Logging in to Azure Container Registry..."
az acr login --name "$ACR_NAME"

# Build and push the Docker image
IMAGE_TAG="$ACR_LOGIN_SERVER/$APP_NAME:latest"
print_info "Building Docker image: $IMAGE_TAG"
docker build -t "$IMAGE_TAG" .

print_info "Pushing Docker image to registry..."
docker push "$IMAGE_TAG"

print_info "Docker image pushed successfully."

# Deploy the application with the new image
print_info "Deploying application to Azure Container Apps..."
DEPLOYMENT_NAME="petclinic-app-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file ./infra/main.bicep \
    --parameters appName="$APP_NAME" \
    --parameters environmentName="$ENVIRONMENT" \
    --parameters containerImage="$IMAGE_TAG" \
    --output none

print_info "Application deployed successfully!"

# Get the application URL
APP_URL=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.outputs.containerAppUrl.value -o tsv)

echo ""
print_info "========================================"
print_info "Deployment completed successfully!"
print_info "========================================"
echo ""
echo "Application URL: $APP_URL"
echo "Resource Group: $RESOURCE_GROUP"
echo "Container Registry: $ACR_LOGIN_SERVER"
echo ""
print_info "You can access your application at: $APP_URL"
