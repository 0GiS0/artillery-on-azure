
### Backend ###
terraform {
  backend "azurerm" {
  }
}

### PROVIDERS ###
provider "azurerm" {
  features {
  }
}

resource "random_pet" "service" {}

### Resource Group ###
resource "azurerm_resource_group" "rg" {
  name     = random_pet.service.id
  location = var.location
}

#Logic App connections
#https://docs.microsoft.com/es-es/azure/logic-apps/logic-apps-azure-resource-manager-templates-overview#connection-resource-definitions
# https://docs.microsoft.com/es-es/azure/logic-apps/logic-apps-azure-resource-manager-templates-overview#authenticate-connections

# IMPORTANT: You have to authenticate the API connections first. If you don't do that the Event Grid connection doesn't create it.

#Event Grid
resource "azurerm_template_deployment" "logicapp_eventgrid_connection" {
  name                = "logicapp_eventgrid_connection"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_body       = file("../../logic-app/connections/eventgrid.json")
  parameters = {
    "location"        = azurerm_resource_group.rg.location
    "connection_name" = var.eventgrid_connection_name
  }

}
#Office 365
resource "azurerm_template_deployment" "logicapp_office365_connection" {
  name                = "logicapp_office365_connection"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_body       = file("../../logic-app/connections/office365.json")

  parameters = {
    "location"        = azurerm_resource_group.rg.location
    "connection_name" = var.office365_connection_name
  }
}
