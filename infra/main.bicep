// Main Bicep file for deploying Spring PetClinic to Azure
targetScope = 'subscription'

@description('Name of the resource group')
param resourceGroupName string = 'rg-petclinic'

@description('Location for all resources')
param location string = 'eastus'

@description('Environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string = 'dev'

@description('Name of the application')
param applicationName string = 'petclinic'

@description('Container image tag')
param containerImageTag string = 'latest'

@description('PostgreSQL administrator login')
@secure()
param postgresAdminLogin string

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

@description('PostgreSQL database name')
param postgresDatabaseName string = 'petclinic'

@description('Enable public network access for PostgreSQL')
param postgresPublicNetworkAccess bool = true

// Variables
var acrName = 'acr${uniqueString(resourceGroup.id)}'

// Create resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: environmentName
    application: applicationName
  }
}

// Deploy Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  scope: resourceGroup
  params: {
    name: acrName
    location: location
    sku: 'Basic'
  }
}

// Deploy Container Apps Environment
module containerAppsEnvironment 'modules/container-apps-environment.bicep' = {
  name: 'containerAppsEnvironment'
  scope: resourceGroup
  params: {
    name: 'cae-${applicationName}-${environmentName}'
    location: location
  }
}

// Deploy PostgreSQL Database
module postgresql 'modules/postgresql.bicep' = {
  name: 'postgresql'
  scope: resourceGroup
  params: {
    serverName: 'psql-${applicationName}-${environmentName}-${uniqueString(resourceGroup.id)}'
    location: location
    administratorLogin: postgresAdminLogin
    administratorPassword: postgresAdminPassword
    databaseName: postgresDatabaseName
    publicNetworkAccess: postgresPublicNetworkAccess
  }
}

// Deploy Container App
module containerApp 'modules/container-app.bicep' = {
  name: 'containerApp'
  scope: resourceGroup
  params: {
    name: 'ca-${applicationName}-${environmentName}'
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerImage: '${containerRegistry.outputs.loginServer}/${applicationName}:${containerImageTag}'
    containerRegistryUrl: containerRegistry.outputs.loginServer
    containerRegistryUsername: acrName
    containerRegistryPassword: listCredentials(resourceId(resourceGroup.name, 'Microsoft.ContainerRegistry/registries', acrName), '2023-11-01-preview').passwords[0].value
    environmentVariables: [
      {
        name: 'SPRING_PROFILES_ACTIVE'
        value: 'postgres'
      }
      {
        name: 'POSTGRES_URL'
        value: 'jdbc:postgresql://${postgresql.outputs.fqdn}:5432/${postgresDatabaseName}?sslmode=require'
      }
      {
        name: 'POSTGRES_USER'
        value: postgresAdminLogin
      }
      {
        name: 'POSTGRES_PASS'
        secretRef: 'postgres-password'
      }
      {
        name: 'JAVA_OPTS'
        value: '-Xmx512m -Xms256m'
      }
    ]
    secrets: [
      {
        name: 'postgres-password'
        value: postgresAdminPassword
      }
    ]
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryName string = containerRegistry.outputs.name
output containerAppUrl string = containerApp.outputs.fqdn
output postgresqlFqdn string = postgresql.outputs.fqdn
output postgresqlDatabaseName string = postgresDatabaseName
