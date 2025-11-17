using 'main.bicep'

param environment = 'poc'
param location = 'France Central'
param resourceNamePrefix = 'apiportal'
param appServicePlanSku = 'F1'
param sqlAdministratorLogin = 'sqladmin'
param sqlAdministratorPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD', 'PocPassword123!')
