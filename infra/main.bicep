targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('MySQL administrator login name')
@secure()
param mysqlAdminLogin string = 'petclinicadmin'

@description('MySQL administrator password')
@secure()
param mysqlAdminPassword string

@description('Name of the App Service Plan')
param appServicePlanName string = ''

@description('Name of the App Service')
param appServiceName string = ''

@description('Name of the MySQL Flexible Server')
param mysqlServerName string = ''

@description('Name of the MySQL database')
param mysqlDatabaseName string = 'petclinic'

@description('Name of the Key Vault')
param keyVaultName string = ''

@description('Name of the Log Analytics workspace')
param logAnalyticsName string = ''

@description('Name of the Application Insights')
param applicationInsightsName string = ''

// Generate unique token for resource naming
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var tags = { 'azd-env-name': environmentName }

// User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${resourceToken}'
  location: location
  tags: tags
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: !empty(logAnalyticsName) ? logAnalyticsName : 'log-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: !empty(applicationInsightsName) ? applicationInsightsName : 'appi-${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: !empty(keyVaultName) ? keyVaultName : 'kv${resourceToken}'
  location: location
  tags: tags
  properties: {
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

// Role assignment for managed identity to access Key Vault
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7') // Key Vault Secrets Officer
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// MySQL Flexible Server
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: !empty(mysqlServerName) ? mysqlServerName : 'mysql-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: mysqlAdminLogin
    administratorLoginPassword: mysqlAdminPassword
    version: '8.0.21'
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}

// MySQL Database
resource mysqlDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-30' = {
  name: mysqlDatabaseName
  parent: mysqlServer
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_unicode_ci'
  }
}

// MySQL Firewall Rule - Allow Azure Services
resource mysqlFirewallRule 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-12-30' = {
  name: 'AllowAzureServices'
  parent: mysqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Store MySQL connection string in Key Vault
resource mysqlConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'MYSQL-URL'
  parent: keyVault
  properties: {
    value: 'jdbc:mysql://${mysqlServer.properties.fullyQualifiedDomainName}:3306/${mysqlDatabaseName}?sslMode=REQUIRED'
  }
  dependsOn: [
    keyVaultRoleAssignment
  ]
}

resource mysqlUserSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'MYSQL-USER'
  parent: keyVault
  properties: {
    value: mysqlAdminLogin
  }
  dependsOn: [
    keyVaultRoleAssignment
  ]
}

resource mysqlPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'MYSQL-PASS'
  parent: keyVault
  properties: {
    value: mysqlAdminPassword
  }
  dependsOn: [
    keyVaultRoleAssignment
  ]
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: !empty(appServicePlanName) ? appServicePlanName : 'plan-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'B2'
    tier: 'Basic'
    size: 'B2'
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: !empty(appServiceName) ? appServiceName : 'app-${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    keyVaultReferenceIdentity: managedIdentity.id
    siteConfig: {
      linuxFxVersion: 'JAVA|17-java17'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: [
          'https://*.azurewebsites.net'
          'https://localhost:*'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'SPRING_PROFILES_ACTIVE'
          value: 'mysql'
        }
        {
          name: 'MYSQL_URL'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=MYSQL-URL)'
        }
        {
          name: 'MYSQL_USER'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=MYSQL-USER)'
        }
        {
          name: 'MYSQL_PASS'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=MYSQL-PASS)'
        }
        {
          name: 'PORT'
          value: '8080'
        }
      ]
    }
  }
  dependsOn: [
    mysqlConnectionStringSecret
    mysqlUserSecret
    mysqlPasswordSecret
    keyVaultRoleAssignment
  ]
}

// Diagnostic settings for App Service
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: appService
  properties: {
    workspaceId: logAnalytics.id
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
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = subscription().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output RESOURCE_GROUP_ID string = resourceGroup().id

output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.properties.ConnectionString
output APPLICATIONINSIGHTS_NAME string = applicationInsights.name

output AZURE_KEY_VAULT_NAME string = keyVault.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.properties.vaultUri

output AZURE_MANAGED_IDENTITY_ID string = managedIdentity.id
output AZURE_MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.properties.clientId

output MYSQL_SERVER_NAME string = mysqlServer.name
output MYSQL_SERVER_FQDN string = mysqlServer.properties.fullyQualifiedDomainName
output MYSQL_DATABASE_NAME string = mysqlDatabaseName

output APP_SERVICE_PLAN_NAME string = appServicePlan.name
output APP_SERVICE_NAME string = appService.name
output APP_SERVICE_URL string = 'https://${appService.properties.defaultHostName}'
