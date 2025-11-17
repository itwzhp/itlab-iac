terraform {
  backend "azurerm" {
    use_oidc             = true
    use_azuread_auth     = true
    storage_account_name = "NAZWA_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
