param nameseed string = 'dbox'
param location string = resourceGroup().location
param projectTeamName string = 'Mobility'

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')
param devboxProjectUser string 

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')


resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' = {
  name: 'DevCenter'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: projectTeamName
  location: location
  properties: {
    devCenterId: dc.id
  }
}


resource dcDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: dc.name
  scope: dc
  properties: {
    workspaceId: logs.id
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
      }
      {
        enabled: true
        categoryGroup: 'audit'
      }
    ]
  }
}

resource logs 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${nameseed}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

output devcenterName string = dc.name