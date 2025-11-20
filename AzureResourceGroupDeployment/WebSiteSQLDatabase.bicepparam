using 'WebSiteSQLDatabase.bicep'

param hostingPlanName = 'megapers-service-plan'
param administratorLogin = 'azureadmin'
param administratorLoginPassword = '@Aa123456' // TODO: Move to Azure Key Vault
param databaseName = 'EmployeesDB'
param webSiteName = 'megapers-webapp'
param sqlserverName = 'megapers-sql'
param location = 'canadacentral'
