output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "azure_function_name" {
  value = azurerm_function_app.function.name
}
