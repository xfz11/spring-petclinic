@description('The name of the app service')
param name string

@description('The location of the app service')
param location string

@description('The resource ID of the app service plan')
param appServicePlanId string

@description('The resource ID of the managed identity')
param managedIdentityId string

@description('Application Insights connection string')
param applicationInsightsConnectionString string

// App Service
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  kind: 'app,linux'
  tags: {
    'azd-service-name': 'web'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'JAVA|17-java17'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        {
          name: 'SPRING_PROFILES_ACTIVE'
          value: 'default'
        }
      ]
    }
  }
}

// Diagnostic settings for App Service
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostics'
  scope: appService
  properties: {
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output id string = appService.id
