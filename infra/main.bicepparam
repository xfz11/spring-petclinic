// Parameters file for Spring PetClinic deployment
using './main.bicep'

// Resource Group Configuration
param resourceGroupName = 'rg-petclinic-dev'
param location = 'eastus'
param environmentName = 'dev'
param applicationName = 'petclinic'

// Container Configuration
param containerImageTag = 'latest'

// PostgreSQL Configuration
param postgresAdminLogin = 'petclinicadmin'
// Note: Set postgresAdminPassword as a secure parameter during deployment
// Example: az deployment sub create --parameters postgresAdminPassword='YourSecurePassword123!'
param postgresAdminPassword = '' // This should be provided at deployment time
param postgresDatabaseName = 'petclinic'
param postgresPublicNetworkAccess = true
