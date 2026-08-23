using './main.bicep'

param staticSiteName = 'jakobferdinand'
param location = 'westeurope'
param storageAccountName = 'stjakobferdinand'
param customDomains = [
  'jakobferdinand.at'
]
param budgetNotificationEmail = 'j.wegenschimmel@gmail.com'
param actionGroupName = 'jakobferdinand-budget-actions'
