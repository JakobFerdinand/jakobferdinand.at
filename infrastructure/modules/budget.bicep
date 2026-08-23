@description('Name of the cost budget.')
param budgetName string

@description('Monthly budget amount in EUR.')
param amount int = 3

@description('Budget start date (ISO 8601, first day of a month).')
param startDate string

@description('Budget end date (ISO 8601).')
param endDate string

@description('Email address used for budget notifications.')
param notificationEmail string

@description('Action group notified on threshold breach.')
param actionGroupName string = 'jakobferdinand-budget-actions'

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    enabled: true
    groupShortName: 'jakobferd'
    emailReceivers: [
      {
        name: 'budget-notifications'
        emailAddress: notificationEmail
        useCommonAlertSchema: true
      }
    ]
    smsReceivers: []
    webhookReceivers: []
  }
}

var notifications = {
  actual_GreaterThan_20_Percent: {
    enabled: true
    operator: 'GreaterThan'
    threshold: 20
    contactGroups: [
      actionGroup.id
    ]
    contactEmails: []
    contactRoles: []
  }
  actual_GreaterThan_80_Percent: {
    enabled: true
    operator: 'GreaterThan'
    threshold: 80
    contactGroups: [
      actionGroup.id
    ]
    contactEmails: []
    contactRoles: []
  }
  actual_GreaterThan_100_Percent: {
    enabled: true
    operator: 'GreaterThan'
    threshold: 100
    contactGroups: [
      actionGroup.id
    ]
    contactEmails: []
    contactRoles: []
  }
}

resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications: notifications
  }
}

output budgetId string = budget.id
