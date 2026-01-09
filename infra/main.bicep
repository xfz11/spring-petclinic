targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

// Optional parameters
@description('PostgreSQL administrator login')
param postgresAdminLogin string = 'petclinicadmin'

@secure()
@description('PostgreSQL administrator password')
param postgresAdminPassword string = ''

@description('PostgreSQL database name')
param postgresDatabaseName string = 'petclinic'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Container registry for storing docker images
module containerRegistry './core/host/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
  }
}

// Container apps environment
module containerAppsEnvironment './core/host/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  scope: rg
  params: {
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    tags: tags
  }
}

// PostgreSQL database
module postgresServer './core/database/postgresql/flexibleserver.bicep' = {
  name: 'postgresql-server'
  scope: rg
  params: {
    name: '${abbrs.dBforPostgreSQLServers}${resourceToken}'
    location: location
    tags: tags
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    databaseNames: [postgresDatabaseName]
    allowAzureIPsFirewall: true
  }
}

// Spring PetClinic web application
module web './core/host/container-app.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: '${abbrs.appContainerApps}web-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    containerRegistryName: containerRegistry.outputs.name
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    env: [
      {
        name: 'SPRING_PROFILES_ACTIVE'
        value: 'postgres'
      }
      {
        name: 'SPRING_DATASOURCE_URL'
        value: 'jdbc:postgresql://${postgresServer.outputs.POSTGRES_DOMAIN_NAME}:5432/${postgresDatabaseName}?sslmode=require'
      }
      {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: postgresAdminLogin
      }
      {
        name: 'SPRING_DATASOURCE_PASSWORD'
        secretRef: 'postgres-password'
      }
    ]
    secrets: [
      {
        name: 'postgres-password'
        value: postgresAdminPassword
      }
    ]
    targetPort: 8080
  }
}

// Output values
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output WEB_URI string = web.outputs.uri
output POSTGRES_SERVER_NAME string = postgresServer.outputs.POSTGRES_SERVER_NAME
output POSTGRES_DATABASE_NAME string = postgresDatabaseName
