// PostgreSQL Flexible Server deployment for Spring PetClinic
// Use the appmod-get-available-region-sku tool to get region and SKU recommendations
// before deploying this template

@description('The location for the PostgreSQL server. Use the region recommended by the tool.')
param location string = resourceGroup().location

@description('The name of the PostgreSQL server')
param serverName string = 'petclinic-postgres-${uniqueString(resourceGroup().id)}'

@description('The administrator username for the PostgreSQL server')
param administratorLogin string = 'petclinic'

@description('The administrator password for the PostgreSQL server')
@secure()
param administratorPassword string

@description('The SKU name for the PostgreSQL server. Recommended: B1ms for dev, D2ds_v4 for prod')
@allowed([
  'B1ms'
  'B2s'
  'D2ds_v4'
  'D4ds_v4'
  'D8ds_v4'
  'E2ds_v4'
  'E4ds_v4'
])
param skuName string = 'B1ms'

@description('The tier of the SKU')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'Burstable'

@description('The version of PostgreSQL')
@allowed([
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
])
param postgresqlVersion string = '16'

@description('The storage size in GB')
param storageSizeGB int = 32

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: postgresqlVersion
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

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  parent: postgresServer
  name: 'petclinic'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Firewall rule configuration
// WARNING: The default rule below allows all Azure services to connect.
// For production deployments, replace this with specific IP addresses or use private endpoints.
// Example: Add firewall rules for specific IPs or IP ranges that need access.
resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// For production, consider using private endpoint instead:
// - Remove the firewall rule above
// - Deploy a private endpoint in your VNet
// - Access PostgreSQL only through private connectivity
// See: https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-networking

output serverFqdn string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = database.name
output serverName string = postgresServer.name
