resource "random_pet" "rg_namepy" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rgpy" {
  location = var.resource_group_location
  name     = random_pet.rg_namepy.id
}

resource "azurerm_virtual_network" "my_terraform_networkpy" {
  name                = "Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rgpy.location
  resource_group_name = azurerm_resource_group.rgpy.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnetpy" {
  name                 = "Subnet"
  resource_group_name  = azurerm_resource_group.rgpy.name
  virtual_network_name = azurerm_virtual_network.my_terraform_networkpy.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ippy" {
  name                = "PublicIP"
  location            = azurerm_resource_group.rgpy.location
  resource_group_name = azurerm_resource_group.rgpy.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsgpy" {
  name                = "NetworkSecurityGroup"
  location            = azurerm_resource_group.rgpy.location
  resource_group_name = azurerm_resource_group.rgpy.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nicpy" {
  name                = "NIC"
  location            = azurerm_resource_group.rgpy.location
  resource_group_name = azurerm_resource_group.rgpy.name

  ip_configuration {
    name                          = "nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnetpy.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ippy.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "connect_py" {
  network_interface_id      = azurerm_network_interface.my_terraform_nicpy.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsgpy.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_idpy" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rgpy.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_accountpy" {
  name                     = "diag${random_id.random_idpy.hex}2"
  location                 = azurerm_resource_group.rgpy.location
  resource_group_name      = azurerm_resource_group.rgpy.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vmpy" {
  name                  = "myPYVM"
  location              = azurerm_resource_group.rgpy.location
  resource_group_name   = azurerm_resource_group.rgpy.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nicpy.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = jsondecode(azapi_resource_action.ssh_public_key_genpy.output).publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_accountpy.primary_blob_endpoint
  }
}