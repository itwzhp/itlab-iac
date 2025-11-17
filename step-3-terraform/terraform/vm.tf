# ------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.azure_rg_name
  location = var.azure_location

  tags = {
    environment = "training"
  }
}

# ------------------------------------------------------------
# Sieć wirtualna i podsieć
# ------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-training"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-training"
  resource_group_name  = var.azure_rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ------------------------------------------------------------
# Public IP
# ------------------------------------------------------------
resource "azurerm_public_ip" "pip" {
  name                = "pip-training"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.rg]
}

# ------------------------------------------------------------
# Network Interface (NIC)
# ------------------------------------------------------------
resource "azurerm_network_interface" "nic" {
  name                = "nic-training"
  location            = var.azure_location
  resource_group_name = var.azure_rg_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# ------------------------------------------------------------
# Network Security Group (NSG)
# Otwiera porty 22 (SSH), 80 (HTTP), 443 (HTTPS)
# ------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-training"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_resource_group.rg]

  # SSH access
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                   = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    description                 = "Allow SSH access"
  }

  # HTTP access
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                   = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    description                 = "Allow HTTP access"
  }

  # HTTPS access
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 120
    direction                   = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "443"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    description                 = "Allow HTTPS access"
  }
}

# ------------------------------------------------------------
# Powiązanie NSG z interfejsem sieciowym
# ------------------------------------------------------------
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ------------------------------------------------------------
# Wirtualna maszyna Linux
# ------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-training"
  resource_group_name   = var.azure_rg_name
  location              = var.azure_location
  size                  = "Standard_B1s"
  zone                  = "1"
  admin_username        = var.vm_user_name
  admin_ssh_key {
    username   = var.vm_user_name
    public_key = var.ssh_pub_key
  }
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-minimal-jammy"
    sku       = "minimal-22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "training"
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_network_interface_security_group_association.nsg_assoc
  ]
}

output "vm_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

resource "local_file" "ansible_inventory" {
  content = templatefile("templates/inventory.tpl", 
    {
      vm_public_ip = azurerm_public_ip.pip.ip_address
      ansible_user = var.vm_user_name
    }
  )
  filename = "${path.module}/hosts.ini"
}
