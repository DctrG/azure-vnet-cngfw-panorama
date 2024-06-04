provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "cngfw_rg" {
  name     = "${var.prefix}-cngfw-rg"
  location = var.location

}

resource "azurerm_public_ip" "cngfw_pip" {
  name                = "${var.prefix}-cngfw-public-ip"
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "cngfw_sg" {
  name                = "${var.prefix}-cngfw-sg"
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name

  security_rule {
    name                       = "AllowPortsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges = [ "80", "8080", "443" ]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }

  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }
}

resource "azurerm_virtual_network" "cngfw_vnet" {
  name                = "${var.prefix}-cngfw-vnet"
  address_space       = ["10.110.0.0/16"]
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name

}

resource "azurerm_subnet" "cngfw_private_subnet" {
  name                 = "${var.prefix}-cngfw-private-subnet"
  resource_group_name  = azurerm_resource_group.cngfw_rg.name
  virtual_network_name = azurerm_virtual_network.cngfw_vnet.name
  address_prefixes     = ["10.110.0.0/24"]

  delegation {
    name = "private"

    service_delegation {
      name = "PaloAltoNetworks.Cloudngfw/firewalls"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "cngfw_private_asso" {
  subnet_id                 = azurerm_subnet.cngfw_private_subnet.id
  network_security_group_id = azurerm_network_security_group.cngfw_sg.id
}

resource "azurerm_subnet" "cngfw_public_subnet" {
  name                 = "${var.prefix}-cngfw-public-subnet"
  resource_group_name  = azurerm_resource_group.cngfw_rg.name
  virtual_network_name = azurerm_virtual_network.cngfw_vnet.name
  address_prefixes     = ["10.110.129.0/24"]

  delegation {
    name = "public"

    service_delegation {
      name = "PaloAltoNetworks.Cloudngfw/firewalls"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "cngfw_public_asso" {
  subnet_id                 = azurerm_subnet.cngfw_public_subnet.id
  network_security_group_id = azurerm_network_security_group.cngfw_sg.id
}

resource "azurerm_virtual_network" "cngfw_spoke_vnet_1" {
  name                = "${var.prefix}-cngfw-spoke-vnet-1"
  address_space       = ["10.112.0.0/16"]
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name
}

resource "azurerm_subnet" "cngfw_subnet_app_1" {
  name                 = "${var.prefix}-cngfw-subnet-app-1"
  resource_group_name  = azurerm_resource_group.cngfw_rg.name
  virtual_network_name = azurerm_virtual_network.cngfw_spoke_vnet_1.name
  address_prefixes     = ["10.112.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "cngfw_app1_asso" {
  subnet_id                 = azurerm_subnet.cngfw_subnet_app_1.id
  network_security_group_id = azurerm_network_security_group.cngfw_sg.id
}

resource "azurerm_virtual_network" "cngfw_spoke_vnet_2" {
  name                = "${var.prefix}-cngfw-spoke-vnet-2"
  address_space       = ["10.113.0.0/16"]
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name
}

resource "azurerm_subnet" "cngfw_subnet_app_2" {
  name                 = "${var.prefix}-cngfw-subnet-app-2"
  resource_group_name  = azurerm_resource_group.cngfw_rg.name
  virtual_network_name = azurerm_virtual_network.cngfw_spoke_vnet_2.name
  address_prefixes     = ["10.113.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "cngfw_app2_asso" {
  subnet_id                 = azurerm_subnet.cngfw_subnet_app_2.id
  network_security_group_id = azurerm_network_security_group.cngfw_sg.id
}

resource "azurerm_virtual_network_peering" "cngfw_peering_hub_to_app_1" {
  name                      = "hub-to-app-1-peering"
  resource_group_name       = azurerm_resource_group.cngfw_rg.name
  virtual_network_name      = azurerm_virtual_network.cngfw_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.cngfw_spoke_vnet_1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "cngfw_peering_app1_to_hub" {
  name                      = "app-1-to-hub-peering"
  resource_group_name       = azurerm_resource_group.cngfw_rg.name
  virtual_network_name      = azurerm_virtual_network.cngfw_spoke_vnet_1.name
  remote_virtual_network_id = azurerm_virtual_network.cngfw_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "cngfw_peering_hub_to_app2" {
  name                      = "hub-to-app-2-peering"
  resource_group_name       = azurerm_resource_group.cngfw_rg.name
  virtual_network_name      = azurerm_virtual_network.cngfw_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.cngfw_spoke_vnet_2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "cngfw_peering_app2_hub" {
  name                      = "app-2-to-hub-peering"
  resource_group_name       = azurerm_resource_group.cngfw_rg.name
  virtual_network_name      = azurerm_virtual_network.cngfw_spoke_vnet_2.name
  remote_virtual_network_id = azurerm_virtual_network.cngfw_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_route_table" "udr" {
  name                = "${var.prefix}-cngfw-route-table"
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name

  route {
    name                   = "route-to-ngfw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.cngfw.network_profile[0].vnet_configuration[0].ip_of_trust_for_user_defined_routes
  }
}

resource "azurerm_subnet_route_table_association" "cngfw_udr_assoc_app_1" {
  subnet_id      = azurerm_subnet.cngfw_subnet_app_1.id
  route_table_id = azurerm_route_table.udr.id
}

resource "azurerm_subnet_route_table_association" "cngfw_udr_assoc_app_2" {
  subnet_id      = azurerm_subnet.cngfw_subnet_app_2.id
  route_table_id = azurerm_route_table.udr.id
}
