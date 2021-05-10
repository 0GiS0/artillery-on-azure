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
}

### App Service Plan ###
resource "azurerm_app_service_plan" "plan" {
  name                = random_pet.service.id
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "elastic"
  reserved            = true
  sku {
    tier = "ElasticPremium"
    size = "EP1"
  }
}


### Azure Function for Puppeter ###
resource "azurerm_function_app" "function" {
  name                       = random_pet.service.id
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  os_type                    = "linux"
  version                    = "~3"

  app_settings = {
    "BUILD_FLAGS"                    = "UseExpressBuild"
    "ENABLE_ORYX_BUILD"              = "true"
    "FUNCTIONS_WORKER_RUNTIME"       = "node"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = 1
  }
}
