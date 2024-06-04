locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
sudo apt -y install apache2
service apache2 start
CUSTOM_DATA
}

resource "azurerm_network_interface" "cngfw_nic" {
  name                = "${var.prefix}cngfw-nic"
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name

  ip_configuration {
    name                          = "${var.prefix}cngfw-nic-config"
    subnet_id                     = azurerm_subnet.cngfw_subnet_app_1.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.112.1.4"
  }
}

resource "azurerm_network_interface" "cngfw_nic_2" {
  name                = "${var.prefix}cngfw-nic-2"
  location            = azurerm_resource_group.cngfw_rg.location
  resource_group_name = azurerm_resource_group.cngfw_rg.name

  ip_configuration {
    name                          = "${var.prefix}cngfw-nic-2-config"
    subnet_id                     = azurerm_subnet.cngfw_subnet_app_2.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.113.1.4"
  }
}

resource "azurerm_storage_account" "cngfw_storage" {
  name                     = "${var.prefix}store"
  location                 = azurerm_resource_group.cngfw_rg.location
  resource_group_name      = azurerm_resource_group.cngfw_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine" "cngfw_linuxvm_1" {
  name                  = "${var.prefix}-cngfw-linuxvm-1"
  location              = azurerm_resource_group.cngfw_rg.location
  resource_group_name   = azurerm_resource_group.cngfw_rg.name
  network_interface_ids = [azurerm_network_interface.cngfw_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "linux-vm1"
  admin_username = "gserrano"
  admin_password = "Paloalto1.000"
  disable_password_authentication = false
  custom_data    = base64encode(local.custom_data)

  boot_diagnostics {
  storage_account_uri = azurerm_storage_account.cngfw_storage.primary_blob_endpoint
  }
}

resource "azurerm_linux_virtual_machine" "cngfw_linuxvm_2" {
  name                  = "${var.prefix}-cngfw-linuxvm-2"
  location              = azurerm_resource_group.cngfw_rg.location
  resource_group_name   = azurerm_resource_group.cngfw_rg.name
  network_interface_ids = [azurerm_network_interface.cngfw_nic_2.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk2"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "linux-vm2"
  admin_username = var.linux_username
  admin_password = var.linux_password
  disable_password_authentication = false
  custom_data    = base64encode(local.custom_data)

  boot_diagnostics {
  storage_account_uri = azurerm_storage_account.cngfw_storage.primary_blob_endpoint
  }
}
