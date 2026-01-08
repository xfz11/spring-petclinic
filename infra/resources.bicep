targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Generate unique token for resource naming
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

// User Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'azid${resourceToken}'
  location: location
}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'azlog${resourceToken}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'azai${resourceToken}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'azplan${resourceToken}'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Web App Service
module webApp 'app/web.bicep' = {
  name: 'web'
  params: {
    name: 'azapp${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.id
    managedIdentityId: managedIdentity.id
    applicationInsightsConnectionString: applicationInsights.properties.ConnectionString
  }
}

// Outputs
output WEB_APP_NAME string = webApp.outputs.name
output WEB_APP_URI string = webApp.outputs.uri
output WEB_APP_IDENTITY_PRINCIPAL_ID string = managedIdentity.properties.principalId
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.properties.ConnectionString
output APPLICATIONINSIGHTS_NAME string = applicationInsights.name
output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.properties.clientId
output MANAGED_IDENTITY_NAME string = managedIdentity.name
output LOG_ANALYTICS_WORKSPACE_NAME string = logAnalyticsWorkspace.name
