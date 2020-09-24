terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

# backend "remote" {
#   organization = "opworks"

#   workspaces {
#     name = "pcInfra"
#   }
# }

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.computer_name
  location = "southeastasia"

  tags = var.tags
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "pcVnet"
  address_space       = ["10.0.0.0/28"]
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "defaultsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/29"]
}

# Create public ip
resource "azurerm_public_ip" "publicip" {
  name                = var.computer_name
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "opscloud"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "opSecure"
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface card
resource "azurerm_network_interface" "nic" {
  name                = "pcNIC"
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "pcNICConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "diagstorage" {
  name                     = var.computer_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "southeastasia"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a windows 10 machine
resource "azurerm_virtual_machine" "vm" {
  name                  = var.computer_name
  location              = "southeastasia"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B2ms"

  storage_os_disk {
    name              = "oakPcOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = lookup(var.sku, var.location)
    version   = "latest"
  }

  os_profile {
    computer_name  = var.computer_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.diagstorage.primary_blob_endpoint
  }
}

data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_virtual_machine.vm.resource_group_name
  depends_on          = [azurerm_virtual_machine.vm]
}

output "public_ip_address" {
  value = data.azurerm_public_ip.ip.ip_address
}
