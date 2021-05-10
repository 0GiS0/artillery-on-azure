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



#File Share on Azure Storage
resource "azurerm_storage_share" "share" {
  name = "load-tests"  
  storage_account_name = data.terraform_remote_state.logic_app.outputs.storage_name
  quota                = 50
}

#Load test file
resource "azurerm_storage_share_file" "example" {
  name             = "load.yaml"
  storage_share_id = azurerm_storage_share.share.id
  source           = "../tests/load.yaml"
}

### Azure Container Group ###
resource "azurerm_container_group" "containergroup" {
  name                = random_pet.service.id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "public"
  dns_name_label      = random_pet.service.id
  os_type             = "Linux"

  restart_policy = "Never"

  container {
    name   = "artillery-${formatdate("HH-mm-DD-MM-YY", timestamp())}"
    image  = "0gis0/artillery-on-aci"
    cpu    = 1
    memory = 1

    volume {
      name                 = "tests"
      mount_path           = "/tests"
      read_only            = true
      storage_account_name = data.terraform_remote_state.logic_app.outputs.storage_name
      storage_account_key  = data.terraform_remote_state.logic_app.outputs.storage_primary_access_key
      share_name           = azurerm_storage_share.share.name
    }

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "ARTILLERY_YAML_FILE"             = "/tests/load.yaml"
      "REPORT_NAME"                     = "returngis"
      "AZURE_STORAGE_CONNECTION_STRING" = data.terraform_remote_state.logic_app.outputs.storage_primary_connection_string
    }
  }
}
