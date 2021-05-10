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

### Storage Account ###
resource "azurerm_storage_account" "storage" {
  name                     = replace(random_pet.service.id, "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
  }

}


#Logic App using ARM
# https://shervyna.medium.com/deploying-logic-app-in-terraform-with-arm-template-ci-cd-e45295244872
resource "azurerm_template_deployment" "logic_app" {
  name                = random_pet.service.id
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_body       = file("../../logic-app/template.json")
  parameters = {
    "office365_connection_name"     = data.terraform_remote_state.api_connections.outputs.office365_connection_name
    "event_grid_connection_name"    = data.terraform_remote_state.api_connections.outputs.eventgrid_connection_name
    "workflow_name"                 = random_pet.service.id
    "workflow_location"             = azurerm_resource_group.rg.location
    "api_connection_resource_group" = data.terraform_remote_state.api_connections.outputs.resource_group_name
    "api_connections_location"      = data.terraform_remote_state.api_connections.outputs.resource_group_location
    "storage_account_id"            = azurerm_storage_account.storage.id
    "storage_static_website_url"    = azurerm_storage_account.storage.primary_web_endpoint
    "puppeteer_resource_group"      = data.terraform_remote_state.puppeteer.outputs.resource_group_name
    "puppeteer_website_name"        = data.terraform_remote_state.puppeteer.outputs.azure_function_name
    "recipients"                    = var.recipients
  }
}
