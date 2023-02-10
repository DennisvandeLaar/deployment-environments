// =========== main.bicep ===========

// Setting target scope
targetScope = 'subscription'

@minLength(1)
param location string = 'westeurope'

@maxLength(10)
@minLength(2)
param name string = 'integrate'

@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

// Create logging resource group
resource logRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}-log-${environment}'
  location: location
}

// Create Log Analytics workspace
module logws './loganalytics.bicep' = {
  name: 'LogWorkspaceDeployment'
  scope: logRg
  params: {
    environment: environment
    name: name
    location: location
  }
}

// Create orchestration resource group
resource orchRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}-orchestration-${environment}'
  location: location
}

// Deploy the logic app service container
module logic './logic-service.bicep' = {
  name: 'LogicAppServiceDeployment'
  scope: orchRg // Deploy to our new or existing RG
  params: { // Pass on shared parameters
    environment: environment
    name: name
    logwsid: logws.outputs.id
    location: location
  }
}

output logic_app string = logic.outputs.app
output logic_plan string = logic.outputs.plan
