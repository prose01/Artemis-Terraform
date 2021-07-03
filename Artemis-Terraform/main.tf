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

# # Generate random text for a unique name
# resource "random_id" "randomId" {
#     keepers = {
#         # Generate a new ID only when a new resource group is defined
#         resource_group = azurerm_resource_group.avalon-group.name
#     }

#     byte_length = 8
# }

# Create resource group
resource "azurerm_resource_group" "avalon-group" {
    name     = "Avalon-ResourceGroup-${var.sourceBranchName}"
    location = "${var.location}"

    tags = {
        Avalon = "${var.sourceBranchName}"
    }
}

# Create app service plan
resource "azurerm_app_service_plan" "avalon-plan" {
    name                = "Avalon-AppServicePlan-${var.sourceBranchName}"
    location            = azurerm_resource_group.avalon-group.location
    resource_group_name = azurerm_resource_group.avalon-group.name
    kind                = "Linux"
    reserved            = true
    
    sku {
        tier = "Standard"
        size = "S1"
    }

    tags = {
        Avalon = azurerm_resource_group.avalon-group.tags.Avalon
    }
}

# Create app service
resource "azurerm_app_service" "avalon" {
    name                = "Avalon-${var.sourceBranchName}"
    location            = azurerm_resource_group.avalon-group.location
    resource_group_name = azurerm_resource_group.avalon-group.name
    app_service_plan_id = azurerm_app_service_plan.avalon-plan.id

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
        "SOME_KEY" = "some-value"
    }

    # connection_string {
    #     name  = "Database"
    #     type  = "SQLServer"
    #     value = "Server=tcp:demosqlserver.database.windows.net,1433;Initial Catalog=demosqldatabase;Persist Security Info=False;User ID=${var.administrator_login};Password=${var.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    # }

    https_only = "true"

    identity {
        type = "SystemAssigned"
    }

    logs {
        http_logs {
            file_system {
                retention_in_mb = 30     # in Megabytes
                retention_in_days = 7 # in days
            }
        }
    }

    tags = {       
        Avalon = azurerm_resource_group.avalon-group.tags.Avalon
    }
}

# # Create app service slot
# resource "azurerm_app_service_slot" "avalon-slot" {
#     name                = "Avalon-staging-${var.sourceBranchName}"
#     location            = azurerm_resource_group.avalon-group.location
#     resource_group_name = azurerm_resource_group.avalon-group.name
#     app_service_plan_id = azurerm_app_service_plan.avalon-plan.id
#     app_service_name    = azurerm_app_service.avalon.name

#     site_config {
#         dotnet_framework_version = "v5.0"
#         # remote_debugging_enabled = true
#         # remote_debugging_version = "VS2019"
#         always_on = "true"
#         ftps_state = "FtpsOnly"
#         http2_enabled = "true"
#         use_32_bit_worker_process = "false"
#         min_tls_version = "1.2"
#     }

#     app_settings = {
#         "SOME_KEY" = "some-value"
#     }

#     # connection_string {
#     #     name  = "Database"
#     #     type  = "SQLServer"
#     #     value = "Server=tcp:demosqlserver.database.windows.net,1433;Initial Catalog=demosqldatabase;Persist Security Info=False;User ID=${var.administrator_login};Password=${var.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
#     # }

#     https_only = "true"

#     identity {
#         type = "SystemAssigned"
#     }

#     logs {
#         application_logs {
#             file_system {
#                 quota = 30     # in Megabytes
#                 retention_period = 30     # in days
#             }
#         }
#     }

#     tags = {       
#         Avalon = azurerm_resource_group.avalon-group.tags.Avalon
#     }
# }

# # Create application insights
# resource "azurerm_application_insights" "my_app_insight" {
#  name                = "my_app_insight"
#  location            = "France central"
#  resource_group_name = "MYRG"
#  application_type    = "Node.JS" # Depends on your application
#  disable_ip_masking  = true
#  retention_in_days   = 730
# }

# # Create storage account
# resource "azurerm_storage_account" "avalonstorageaccount" {
#     name                        = "${random_id.randomId.hex}${var.sourceBranchName}"
#     resource_group_name         = azurerm_resource_group.avalon-group.name
#     location                    = azurerm_resource_group.avalon-group.location
#     account_replication_type    = "${var.storage_replication_type}"
#     account_tier                = "${var.storage_account_tier}"

#     tags = {
#         Avalon = azurerm_resource_group.avalon-group.tags.Avalon
#     }
# }

# # Create container
# resource "azurerm_storage_container" "avaloncontainer" {
#   name                 = "avalonstoragecontainer-${var.sourceBranchName}"
#   storage_account_name = azurerm_storage_account.avalonstorageaccount.name
# }

# # Create sql server
# resource "azurerm_sql_server" "demosqlserver" {
#   name                         = "msdemosqlserver-${var.sourceBranchName}"
#   resource_group_name          = azurerm_resource_group.avalon-group.name
#   location                     = azurerm_resource_group.avalon-group.location
#   version                      = "12.0"
#   administrator_login          = "${var.administrator_login}"
#   administrator_login_password = "thisIsDog11"

#   tags = {
#        environment = azurerm_resource_group.avalon-group.tags.environment
#        build       = azurerm_resource_group.avalon-group.tags.build
#        myterraformgroup = azurerm_resource_group.avalon-group.tags.myterraformgroup
#   }
# }

# # Create sql database
# resource "azurerm_sql_database" "demosqldatabase" {
#   name                = "mydemosqldatabase-${var.sourceBranchName}"
#   resource_group_name = azurerm_resource_group.avalon-group.name
#   location            = azurerm_resource_group.avalon-group.location
#   server_name         = azurerm_sql_server.demosqlserver.name

#   extended_auditing_policy {
#     storage_endpoint                        = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
#     storage_account_access_key              = azurerm_storage_account.mystorageaccount.primary_access_key
#     storage_account_access_key_is_secondary = true
#     retention_in_days                       = 6
#   }

#   tags = {
#        environment = azurerm_resource_group.avalon-group.tags.environment
#        build       = azurerm_resource_group.avalon-group.tags.build
#        myterraformgroup = azurerm_resource_group.avalon-group.tags.myterraformgroup
#   }
# }