# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used 
terraform {
  backend "azurerm" {
  }
}

# Configure the Azure provider
provider "azurerm" {
    skip_provider_registration = true
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
    features {}
}

# Generate random text for a unique name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.artemis-group.name
    }

    byte_length = 1
}

# Create resource group
resource "azurerm_resource_group" "artemis-group" {
    name     = "Artemis-${var.sourceBranchName}"
    location = "${var.location}"

    tags = {
        Artemis = "${var.sourceBranchName}"
    }
}

# Create app service plan
resource "azurerm_app_service_plan" "artemis-plan" {
    name                = "Artemis-AppServicePlan-${var.sourceBranchName}"
    location            = azurerm_resource_group.artemis-group.location
    resource_group_name = azurerm_resource_group.artemis-group.name
    kind                = "Linux"
    reserved            = true
    
    sku {
        tier = "Standard"
        size = "P1V2"
    }

    tags = {
        Artemis = azurerm_resource_group.artemis-group.tags.Artemis
    }
}

# Create app service
resource "azurerm_app_service" "artemis" {
    name                = "Artemis-${random_id.randomId.hex}-${var.sourceBranchName}"
    location            = azurerm_resource_group.artemis-group.location
    resource_group_name = azurerm_resource_group.artemis-group.name
    app_service_plan_id = azurerm_app_service_plan.artemis-plan.id

    site_config {
        dotnet_framework_version = "v5.0"
        linux_fx_version = "v5.0"
        # remote_debugging_enabled = true
        # remote_debugging_version = "VS2019"
        always_on = "true"
        ftps_state = "FtpsOnly"
        http2_enabled = "true"
        use_32_bit_worker_process = "false"
        min_tls_version = "1.2"
    }

    app_settings = {
        "AllowedHosts" = "${var.allowedhosts}"
        "Mongo_Database" = "Avalon"
        "Auth0_Domain" = "${var.auth0domain}"
        "Auth0_ApiIdentifier" = "${var.auth0apiIdentifier}"
        "Auth0_Claims_nameidentifier" = "${var.auth0claimsnameidentifier}"
        "FileSizeLimit" = "2097152"
        "MaxImageNumber" = "10"
    }

    https_only = "true"

    identity {
        type = "SystemAssigned"
    }

    logs {
        http_logs {
            file_system {
                retention_in_mb = 30  # in Megabytes
                retention_in_days = 7 # in days
            }
        }
    }

    tags = {       
        Artemis = azurerm_resource_group.artemis-group.tags.Artemis
    }
}

# Create app service slot
resource "azurerm_app_service_slot" "artemis-slot" {
    name                = "Artemis-staging-${var.sourceBranchName}"
    location            = azurerm_resource_group.artemis-group.location
    resource_group_name = azurerm_resource_group.artemis-group.name
    app_service_plan_id = azurerm_app_service_plan.artemis-plan.id
    app_service_name    = azurerm_app_service.artemis.name

    site_config {
        dotnet_framework_version = "v5.0"
        # remote_debugging_enabled = true
        # remote_debugging_version = "VS2019"
        always_on = "true"
        ftps_state = "FtpsOnly"
        http2_enabled = "true"
        use_32_bit_worker_process = "false"
        min_tls_version = "1.2"
    }

    app_settings = {
        "AllowedHosts" = "${var.allowedhosts}"
        "Mongo_Database" = "Avalon"
        "Auth0_Domain" = "${var.auth0domain}"
        "Auth0_ApiIdentifier" = "${var.auth0apiIdentifier}"
        "Auth0_Claims_nameidentifier" = "${var.auth0claimsnameidentifier}"
        "FileSizeLimit" = "2097152"
        "MaxImageNumber" = "10"
    }

    https_only = "true"

    identity {
        type = "SystemAssigned"
    }

    logs {
        http_logs {
            file_system {
                retention_in_mb = 30 # in Megabytes
                retention_in_days = 7 # in days
            }
        }
    }

    tags = {       
        Artemis = azurerm_resource_group.artemis-group.tags.Artemis
    }
}

# # Create application insights. Obs! Not working for Linux!
# resource "azurerm_application_insights" "artemis-insights" {
#  name                = "artemis-insights"
#  location            = azurerm_resource_group.artemis-group.location
#  resource_group_name = azurerm_resource_group.artemis-group.name
#  application_type    = "web"
#  disable_ip_masking  = false
#  retention_in_days   = 30

#  tags = {       
#         Artemis = azurerm_resource_group.artemis-group.tags.Artemis
#     }
# }

# # Create storage account
# resource "azurerm_storage_account" "artemisstorageaccount" {
#     name                        = "${random_id.randomId.hex}${var.sourceBranchName}"
#     resource_group_name         = azurerm_resource_group.artemis-group.name
#     location                    = azurerm_resource_group.artemis-group.location
#     account_replication_type    = "${var.storage_replication_type}"
#     account_tier                = "${var.storage_account_tier}"

#     tags = {
#         Artemis = azurerm_resource_group.artemis-group.tags.Artemis
#     }
# }

# # Create container
# resource "azurerm_storage_container" "artemis-storage-container" {
#   name                 = "artemis-storage-container-${var.sourceBranchName}"
#   storage_account_name = azurerm_storage_account.artemisstorageaccount.name
# }