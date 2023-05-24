provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rscraper" {
  name     = var.environment_name
  location = "North Central US"
}

data "azurerm_storage_account" "rscraper" {
  name                = var.storage_account_name
  resource_group_name = "tube"
}

resource "azurerm_storage_share" "rscraper" {
  name                 = "appstorage"
  storage_account_name = azurerm_storage_account.rscraper.name
  quota                = 5120
  tier                 = "TransactionOptimized"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_log_analytics_workspace" "rscraper" {
  name                = var.environment_name
  location            = azurerm_resource_group.rscraper.location
  resource_group_name = azurerm_resource_group.rscraper.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment_storage" "rscraper" {
  name                         = var.environment_name
  container_app_environment_id = azurerm_container_app_environment.rscraper.id
  account_name                 = azurerm_storage_account.rscraper.name
  share_name                   = azurerm_storage_share.rscraper.name
  access_key                   = azurerm_storage_account.rscraper.primary_access_key
  access_mode                  = "ReadOnly"
}

resource "azurerm_container_app_environment" "rscraper" {
  name                       = var.environment_name
  location                   = azurerm_resource_group.rscraper.location
  resource_group_name        = azurerm_resource_group.rscraper.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.rscraper.id
}
resource "azurerm_container_app" "rscraper" {
  name                         = var.environment_name
  container_app_environment_id = azurerm_container_app_environment.rscraper.id
  resource_group_name          = azurerm_resource_group.rscraper.name
  revision_mode                = "Single"

  template {
    container {
      name   = "examplecontainerapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}