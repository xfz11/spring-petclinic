targetScope = 'subscription'

@description('Name of the environment (used for resource naming)')
param environmentName string

@description('Primary location for all resources')
param location string

@description('Container image to deploy (use default for initial deployment)')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Container app port')
param containerPort int = 8080

@description('Minimum number of replicas')
param minReplicas int = 0

var resourceToken = uniqueString(subscription().id, location, environmentName)
var resourceGroupName = 'rg-${environmentName}'

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

// Deploy all resources into the resource group
module resources 'resources.bicep' = {
  name: 'resources-deployment'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    resourceToken: resourceToken
    containerImage: containerImage
    containerPort: containerPort
    minReplicas: minReplicas
  }
}

output resourceGroupName string = rg.name
output containerAppName string = resources.outputs.containerAppName
output containerRegistryName string = resources.outputs.containerRegistryName
output containerRegistryLoginServer string = resources.outputs.containerRegistryLoginServer
output containerAppFqdn string = resources.outputs.containerAppFqdn
