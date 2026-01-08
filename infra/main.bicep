targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = 'rg-${environmentName}'

// Tags to apply to all resources
var tags = {
  'azd-env-name': environmentName
}

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy resources
module resources 'resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output RESOURCE_GROUP_ID string = rg.id
output AZURE_RESOURCE_GROUP string = rg.name

// App Service outputs
output WEB_APP_NAME string = resources.outputs.WEB_APP_NAME
output WEB_APP_URI string = resources.outputs.WEB_APP_URI
output WEB_APP_IDENTITY_PRINCIPAL_ID string = resources.outputs.WEB_APP_IDENTITY_PRINCIPAL_ID

// Supporting services outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
output APPLICATIONINSIGHTS_NAME string = resources.outputs.APPLICATIONINSIGHTS_NAME
