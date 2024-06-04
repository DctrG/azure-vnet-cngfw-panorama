terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azapi" {
}

resource "azurerm_log_analytics_workspace" "cngfw_logs" {
  name                = "${var.prefix}-cngfw-logs"
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azapi_resource_action" "enable_logging" {
  type        = "PaloAltoNetworks.Cloudngfw/firewalls@2023-09-01"
  resource_id = azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.cngfw.id
  action      = "saveLogProfile"
  method      = "POST"
  body = jsonencode({
    logType   = "TRAFFIC"
    logOption = "SAME_DESTINATION"
    commonDestination = {
      monitorConfigurations = {
        id           = azurerm_log_analytics_workspace.cngfw_logs.id
        workspace    = azurerm_log_analytics_workspace.cngfw_logs.workspace_id
        primaryKey   = azurerm_log_analytics_workspace.cngfw_logs.primary_shared_key
        secondaryKey = azurerm_log_analytics_workspace.cngfw_logs.secondary_shared_key
      }
    }
  })
}