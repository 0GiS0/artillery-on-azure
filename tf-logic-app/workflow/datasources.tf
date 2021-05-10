data "azurerm_client_config" "current" {

}
data "azurerm_subscription" "current" {
}


#Data from puppeteer deployment
data "terraform_remote_state" "puppeteer" {
  backend = "azurerm"
  config = {
    storage_account_name = "statestf"
    container_name       = "artillery"
    key                  = "puppeteer.tfstate"
    access_key           = var.access_key
  }
}

#Data from API connections

data "terraform_remote_state" "api_connections" {
  backend = "azurerm"
  config = {
    storage_account_name = "statestf"
    container_name       = "artillery"
    key                  = "api-connections.tfstate"
    access_key           = var.access_key
  }
}
