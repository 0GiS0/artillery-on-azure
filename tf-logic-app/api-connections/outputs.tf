output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.rg.location
}

output "office365_connection_name" {
  value = var.office365_connection_name
}

output "eventgrid_connection_name" {
value = var.eventgrid_connection_name
}

output "event_grid_test_link" {
  value = "${var.azure_portal_url}/#@${var.azuread_domain}/resource/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${var.eventgrid_connection_name}/edit"
}

output "office365_test_link" {
  value = "${var.azure_portal_url}#@${var.azuread_domain}/resource/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${var.office365_connection_name}/edit"
}
