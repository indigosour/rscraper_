provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rscraper" {
  name     = var.environment_name
  location = var.location
}

data "azurerm_storage_account" "rscraper" {
  name                = var.storage_account_name
  resource_group_name = var.storage_account_rg
}

data "azurerm_key_vault_secret" "rscraper_ghcr_cred" {
  name         = "ghcr-cred"
  key_vault_id = var.key_vault_id
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
  account_name                 = data.azurerm_storage_account.rscraper.name
  share_name                   = var.storage_account_share_name
  access_key                   = data.azurerm_storage_account.rscraper.primary_access_key
  access_mode                  = "ReadOnly"
}

resource "azurerm_container_app_environment" "rscraper" {
  name                       = var.environment_name
  location                   = azurerm_resource_group.rscraper.location
  resource_group_name        = azurerm_resource_group.rscraper.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.rscraper.id
}

resource "azurerm_container_app" "rscraper_conductor" {
  name                         = var.environment_name
  container_app_environment_id = azurerm_container_app_environment.rscraper.id
  resource_group_name          = azurerm_resource_group.rscraper.name
  revision_mode                = "Single"

  secret {
    name  = "ghcr-cred"
    value = jsondecode(data.azurerm_key_vault_secret.rscraper_ghcr_cred.value).docker_password
  }

  registry {
    server   = jsondecode(data.azurerm_key_vault_secret.rscraper_ghcr_cred.value).docker_server
    username = jsondecode(data.azurerm_key_vault_secret.rscraper_ghcr_cred.value).docker_username
    password_secret_name = "ghcr-cred"
  }

  template {
    max_replicas = 1
    min_replicas = 1

    container {
      name   = "rscraper-conductor"
      image  = var.rscraper_conductor_image
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}


resource "azurerm_container_app" "rscraper_worker" {
  name                         = var.environment_name
  container_app_environment_id = azurerm_container_app_environment.rscraper.id
  resource_group_name          = azurerm_resource_group.rscraper.name
  revision_mode                = "Single"

  secret {
    name  = "ghcr-cred"
    value = jsondecode(data.azurerm_key_vault_secret.rscraper_ghcr_cred.value).docker_password
  }

  registry {
    server   = jsondecode(data.azurerm_key_vault_secret.rscraper_ghcr_cred.value).docker_server
    username = jsondecode(data.azurerm_key_vault_secret.rscraper_ghcr_cred.value).docker_username
    password_secret_name = "ghcr-cred"
  }

  template {
    max_replicas = 5
    min_replicas = 0

    container {
      name   = "rscraper-worker"
      image  = var.rscraper_worker_image
      cpu    = 2
      memory = "4Gi"
    }
  }
}