// Azure Container App module for Spring PetClinic
@description('Name of the Container App')
param name string

@description('Location for the Container App')
param location string = resourceGroup().location

@description('Container Apps Environment ID')
param containerAppsEnvironmentId string

@description('Container image')
param containerImage string

@description('Container Registry URL')
param containerRegistryUrl string

@description('Container Registry username')
param containerRegistryUsername string

@description('Container Registry password')
@secure()
param containerRegistryPassword string

@description('Environment variables')
param environmentVariables array = []

@description('Secrets')
param secrets array = []

@description('CPU cores allocated to the container')
param cpu string = '0.5'

@description('Memory allocated to the container')
param memory string = '1Gi'

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 3

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: [
        {
          server: containerRegistryUrl
          username: containerRegistryUsername
          passwordSecretRef: 'registry-password'
        }
      ]
      secrets: concat([
        {
          name: 'registry-password'
          value: containerRegistryPassword
        }
      ], secrets)
    }
    template: {
      containers: [
        {
          name: 'petclinic'
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: environmentVariables
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/actuator/health/liveness'
                port: 8080
                scheme: 'HTTP'
              }
              initialDelaySeconds: 30
              periodSeconds: 10
              timeoutSeconds: 5
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/actuator/health/readiness'
                port: 8080
                scheme: 'HTTP'
              }
              initialDelaySeconds: 10
              periodSeconds: 5
              timeoutSeconds: 3
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output id string = containerApp.id
output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output url string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
