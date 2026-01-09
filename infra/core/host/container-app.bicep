param name string
param location string = resourceGroup().location
param tags object = {}

@description('Allowed origins')
param allowedOrigins array = []

@description('Name of the environment for container apps')
param containerAppsEnvironmentName string = ''

@description('CPU cores allocated to a single container instance, e.g., 0.5')
param containerCpuCoreCount string = '0.5'

@description('The maximum number of replicas to run. Must be at least 1.')
@minValue(1)
param containerMaxReplicas int = 10

@description('Memory allocated to a single container instance, e.g., 1Gi')
param containerMemory string = '1.0Gi'

@description('The minimum number of replicas to run. Must be at least 1.')
param containerMinReplicas int = 1

@description('The name of the container')
param containerName string = 'main'

@description('The name of the container registry')
param containerRegistryName string = ''

@description('Hostname suffix for container registry. Set when deploying to sovereign clouds')
param containerRegistryHostSuffix string = 'azurecr.io'

@description('The environment variables for the container')
param env array = []

@description('Specifies if the resource ingress is exposed externally')
param external bool = true

@description('The name of the user-assigned identity')
param identityName string = ''

@description('The type of identity for the resource')
@allowed(['None', 'SystemAssigned', 'UserAssigned'])
param identityType string = 'None'

@description('The name of the container image')
param imageName string = ''

@description('Specifies if Ingress is enabled for the container app')
param ingressEnabled bool = true

param revisionMode string = 'Single'

@description('The secrets required for the container')
param secrets array = []

@description('The service binds associated with the container')
param serviceBinds array = []

@description('The name of the container apps add-on to use. e.g. redis')
param serviceType string = ''

@description('The target port for the container')
param targetPort int = 80

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppsEnvironmentName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = if (!empty(containerRegistryName)) {
  name: containerRegistryName
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (!empty(identityName)) {
  name: identityName
}

module containerRegistryAccess './container-registry-access.bicep' = if (!empty(containerRegistryName)) {
  name: '${deployment().name}-registry-access'
  params: {
    containerRegistryName: containerRegistryName
    principalId: identityType == 'SystemAssigned' ? containerApp.identity.principalId : userIdentity.properties.principalId
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: identityType == 'SystemAssigned' ? {
    type: identityType
  } : identityType == 'UserAssigned' ? {
    type: identityType
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  } : {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: revisionMode
      ingress: ingressEnabled ? {
        external: external
        targetPort: targetPort
        transport: 'auto'
        corsPolicy: {
          allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
        }
      } : null
      registries: !empty(containerRegistryName) ? [
        {
          server: '${containerRegistryName}.${containerRegistryHostSuffix}'
          identity: identityType == 'UserAssigned' ? userIdentity.id : 'system'
        }
      ] : []
      secrets: secrets
      service: !empty(serviceType) ? {
        type: serviceType
      } : null
    }
    template: {
      serviceBinds: !empty(serviceBinds) ? serviceBinds : null
      containers: [
        {
          image: !empty(imageName) ? imageName : 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: containerName
          env: env
          resources: {
            cpu: json(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]
      scale: {
        minReplicas: containerMinReplicas
        maxReplicas: containerMaxReplicas
      }
    }
  }
}

output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
output identityPrincipalId string = identityType == 'None' ? '' : (identityType == 'SystemAssigned' ? containerApp.identity.principalId : userIdentity.properties.principalId)
output imageName string = imageName
output name string = containerApp.name
output serviceBind object = !empty(serviceType) ? { serviceId: containerApp.id, name: name } : {}
output uri string = ingressEnabled ? 'https://${containerApp.properties.configuration.ingress.fqdn}' : ''
