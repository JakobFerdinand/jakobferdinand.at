using './main.bicep'

param staticSiteName = 'jakobferdinand'
param location = 'westeurope'
param customDomains = [
  'jakobferdinand.at'
]
param budgetNotificationEmail = 'j.wegenschimmel@gmail.com'
param actionGroupName = 'jakobferdinand-budget-actions'
