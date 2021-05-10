#Data from Logic App Deployment
data "terraform_remote_state" "logic_app" {
  backend = "azurerm"
  config = {
    storage_account_name = "statestf"
    container_name       = "artillery"
    key                  = "logicapp.tfstate"
    access_key           = "e8m3VVBbDoqg+g77KTwCDmQYxojUPby+PHn40b7GJfaz/sNTZ/30n8YZRFmMAeqzCRPAsFiElUmDvNkqOc7QTA=="
  }
}
