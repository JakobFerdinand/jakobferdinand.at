targetScope = 'resourceGroup'

@description('Name of the existing static web app.')
param staticSiteName string

@description('Region of the static web app.')
param location string

@description('Custom domains for the static web app.')
param customDomains array = []

@description('Name of the cost budget.')
param budgetName string = 'Jakobferdinand-Budget'

@description('Monthly budget amount in EUR.')
param budgetAmount int = 3

@description('Budget start date (ISO 8601, first day of a month).')
param budgetStartDate string = '2026-09-01T00:00:00Z'

@description('Budget end date (ISO 8601).')
param budgetEndDate string = '2030-12-31T00:00:00Z'

@description('Email address used for budget notifications (non-secret configuration).')
param budgetNotificationEmail string

@description('Action group notified on budget threshold breach.')
param actionGroupName string = 'jakobferdinand-budget-actions'

@description('Name of the storage account for website analytics.')
param storageAccountName string

module storage './modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    location: location
  }
}

module staticSites './modules/static-sites.bicep' = {
  name: 'staticSites'
  params: {
    siteName: staticSiteName
    location: location
    customDomains: customDomains
  }
}

module budget './modules/budget.bicep' = {
  name: 'budget'
  params: {
    budgetName: budgetName
    amount: budgetAmount
    startDate: budgetStartDate
    endDate: budgetEndDate
    notificationEmail: budgetNotificationEmail
    actionGroupName: actionGroupName
  }
}
