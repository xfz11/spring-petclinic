param name string
param location string = resourceGroup().location
param tags object = {}

@description('The administrator login for the PostgreSQL server')
param administratorLogin string

@secure()
@description('The administrator password for the PostgreSQL server')
param administratorLoginPassword string

@description('The database names to create on the server')
param databaseNames array = []

@description('Whether to allow Azure services to access this server')
param allowAzureIPsFirewall bool = false

@description('PostgreSQL Server version')
@allowed([
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
])
param version string = '16'

@description('PostgreSQL Server tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param tier string = 'Burstable'

@description('PostgreSQL Server SKU name')
param skuName string = 'Standard_B1ms'

@description('Storage size in GB')
param storageSizeGB int = 32

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: tier
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGB
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

resource databases 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = [for databaseName in databaseNames: {
  name: databaseName
  parent: postgresServer
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}]

resource allowAzureIPsFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = if (allowAzureIPsFirewall) {
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  parent: postgresServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output POSTGRES_SERVER_NAME string = postgresServer.name
output POSTGRES_DOMAIN_NAME string = postgresServer.properties.fullyQualifiedDomainName
