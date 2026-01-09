param name string
param location string = resourceGroup().location
param tags object = {}

@description('Application Insights resource name')
param applicationInsightsName string = ''

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = ''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!empty(logAnalyticsWorkspaceName)) {
  name: logAnalyticsWorkspaceName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: !empty(logAnalyticsWorkspaceName) ? {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    } : null
    daprAIInstrumentationKey: !empty(applicationInsightsName) ? reference(resourceId('Microsoft.Insights/components', applicationInsightsName), '2020-02-02').InstrumentationKey : ''
    zoneRedundant: false
  }
}

output name string = containerAppsEnvironment.name
output id string = containerAppsEnvironment.id
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
