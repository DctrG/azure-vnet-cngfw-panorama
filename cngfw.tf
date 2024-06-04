resource "azurerm_palo_alto_next_generation_firewall_virtual_network_panorama" "cngfw" {
  name                   = "${var.prefix}-cngfw-firewall"
  resource_group_name    = azurerm_resource_group.cngfw_rg.name
  location               = azurerm_resource_group.cngfw_rg.location
  panorama_base64_config = var.panorama-string

  network_profile {
    public_ip_address_ids = [azurerm_public_ip.cngfw_pip.id]
    egress_nat_ip_address_ids = [ azurerm_public_ip.cngfw_pip.id ]

    vnet_configuration {
      virtual_network_id  = azurerm_virtual_network.cngfw_vnet.id
      trusted_subnet_id   = azurerm_subnet.cngfw_private_subnet.id
      untrusted_subnet_id = azurerm_subnet.cngfw_public_subnet.id
    }
  }

  dns_settings {
    use_azure_dns = true
  }

  destination_nat {
    name = "webserver"
    protocol = "TCP"

  backend_config {
    port = 80
    public_ip_address = azurerm_linux_virtual_machine.cngfw_linuxvm_1.private_ip_address
  }

  frontend_config {
    port = 8080
    public_ip_address_id = azurerm_public_ip.cngfw_pip.id
  }

  }
}

output "cngfw_public_ip_address" {
  description = "Cloud NGFW Public IP Address"
  value = azurerm_public_ip.cngfw_pip.ip_address
}
