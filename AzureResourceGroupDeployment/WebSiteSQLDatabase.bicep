@description('The name of the App Service Plan')
param hostingPlanName string

@description('The pricing tier for the App Service Plan')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'F1'

@description('The number of instances for the App Service Plan')
@minValue(1)
param skuCapacity int = 1

@description('The administrator username for SQL Server')
param administratorLogin string

@description('The administrator password for SQL Server')
@secure()
param administratorLoginPassword string

@description('The name of the SQL Database')
param databaseName string

@description('The collation for the SQL Database')
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('The edition of the SQL Database')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param edition string = 'Basic'

@description('The maximum size of the database in bytes')
param maxSizeBytes string = '1073741824'

@description('The performance level for the database edition')
@allowed([
  'Basic'
  'S0'
  'S1'
  'S2'
  'P1'
  'P2'
  'P3'
])
param requestedServiceObjectiveName string = 'Basic'

@description('The name of the Web App')
param webSiteName string

@description('The name of the SQL Server')
param sqlserverName string = 'megapers-sql'

@description('The location for all resources')
param location string = resourceGroup().location

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlserverName
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: {
    displayName: 'Database'
  }
  sku: {
    name: requestedServiceObjectiveName
    tier: edition
  }
  properties: {
    collation: collation
    maxSizeBytes: int(maxSizeBytes)
  }
}

// SQL Server Firewall Rule - Allow Azure Services
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {}
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webSiteName
  location: location
  tags: {
    displayName: 'Website'
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'empty'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'dotnet'
        }
      ]
    }
  }
}

// Web App Connection String
resource webAppConnectionStrings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: webApp
  name: 'connectionstrings'
  properties: {
    WebAppContext: {
      value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};User Id=${administratorLogin}@${sqlserverName};Password=${administratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
}

// Outputs
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseName string = sqlDatabase.name
