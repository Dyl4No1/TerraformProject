# change storage subnet to gateway subnet
# add priv/public storage
# see help.txt in onedrive directory
# only thing changed here, second vmsa and boot diag commmented out

resource "azurerm_management_group" "iBeacon-mng"{
  name = "iBeacon-mng"
}

resource "azurerm_management_group" "production-iBeacon-mng" {
  display_name = "production-iBeacon-mng"
  #name = "00000000-0000-0000-0000-000000000000"
  parent_management_group_id = azurerm_management_group.iBeacon-mng.id
}

##mng-sub pairings
resource "azurerm_management_group_subscription_association" "ass1" {
  management_group_id = azurerm_management_group.iBeacon-mng.id
  subscription_id = "/subscriptions/6f194a23-0fc5-4a6b-8df5-8ac9c2723c63"
} 
# resource "azurerm_management_group_subscription_association" "ass2" {
#   management_group_id = azurerm_management_group.production-iBeacon-mng.id
#   subscription_id = azurerm_subscription.sql.id
# } 
# resource "azurerm_management_group_subscription_association" "ass3" {
#   management_group_id = azurerm_management_group.production-iBeacon-mng.id
#   subscription_id = azurerm_subscription.storage.id
# }################

# resource "azurerm_role_definition" "example" {
#   role_definition_id = "00000000-0000-0000-0000-000000000000"
#   name               = "my-custom-role-definition"
#   scope              = data.azurerm_subscription.web.id

#   permissions {
#     actions     = ["Microsoft.Resources/subscriptions/resourceGroups/read"]
#     not_actions = []
#   }

#   assignable_scopes = [
#     azurerm_subscription.web.id,
#   ]
# }

## if this causes errors, comment out. will be used in cost comparison though.
resource "azurerm_network_ddos_protection_plan" "ddos" {
  name                = "ddos_plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create Resource group for web vms
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "rg"                           #can use ${random_pet.prefix.id} for randomised name
}
# resource "azurerm_virtual_hub" "azhub" { doesnt work :()
#   name = "azhub"
#   resource_group_name = azurerm_resource_group.rg.name
#   location = azurerm_resource_group.rg.location
#   address_prefix = "169.254.21.2"
# }
# resource "azurerm_vpn_gateway" "azgcpgw" {
#   name = "azgcpgw"
#   location = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   virtual_hub_id = azurerm_virtual_hub.azhub.id
#}
# Create virtual network with relevant address space
resource "azurerm_virtual_network" "NETWORK-A" {
  name                = "NETWORK-A"
  address_space       = ["10.2.0.0/16"]  ## keep broad as unknown number of devices
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
#Create subnets for separte sections
resource "azurerm_subnet" "GatewaySubnet" { ## Gateway subnet
  name                 = "GatewaySubnet"          #"${random_pet.prefix.id}-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.NETWORK-A.name
  address_prefixes     = ["10.2.0.0/27"]
}
resource "azurerm_subnet" "webVmSubnet" { ## web subnet
  name                 = "webVmSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.NETWORK-A.name
  address_prefixes     = ["10.2.1.0/24"]
}
resource "azurerm_subnet" "sqlVmSubnet" { ## sql subnet
  name                 = "sqlVmSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.NETWORK-A.name
  address_prefixes     = ["10.2.2.0/24"]
}
# Create public IP address for web
resource "azurerm_public_ip" "iBeacon-pubIP" {
  name                = "iBeacon-pubIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
# Create public IP address for sql
resource "azurerm_public_ip" "iBeacon-pubIP2" {
  name                = "iBeacon-pubIP2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
######## for web lb
resource "azurerm_public_ip" "iBeacon-pubIP3" {
  name                = "iBeacon-pubIP3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
# Create Network Security Group and rules
resource "azurerm_network_security_group" "iBeacon-nsg" {
  name                = "iBeacon-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule { ## http
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # security_rule { ## https
  #   name                       = "https"
  #   priority                   = 1005
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "443"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }
  security_rule {
    name                       = "sql"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule { ## for ping
    name                       = "ICMPin"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ICMPout"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface for web
resource "azurerm_network_interface" "iBeacon-nic" {
  name                = "iBeacon-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "iBeacon-nic"
    subnet_id                     = azurerm_subnet.webVmSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.iBeacon-pubIP.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg1" {
  network_interface_id      = azurerm_network_interface.iBeacon-nic.id
  network_security_group_id = azurerm_network_security_group.iBeacon-nsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "websa" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create web virtual machine
resource "azurerm_windows_virtual_machine" "webVM" {
  name                  = "az-webvm1"
  admin_username        = "azureuser"
  admin_password        = random_password.password.result
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.iBeacon-nic.id]
  size                  = "Standard_DS1_v2"

  os_disk { ## tweak for performance ?
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.websa.primary_blob_endpoint
  }
}

# Install IIS web server to the virtual machine
resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = "${random_pet.prefix.id}-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.webVM.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}
resource "azurerm_lb" "weblb" { ## external lb hence public IP
  name                = "weblb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "weblb_ip"
    public_ip_address_id = azurerm_public_ip.iBeacon-pubIP3.id
  }
}

## sql implementation
# resource "azurerm_storage_account" "sqlsa" {
#   name = "sqlibeaconsa"
#   resource_group_name = azurerm_resource_group.rg.name

#   location = azurerm_resource_group.rg.location
#   account_tier = "Premium"
#   account_replication_type = "ZRS" ## Zone Redundant Storage
#   cross_tenant_replication_enabled = true # cross vendor replication ?
#   #enable_https_traffic_only = t/f
#   min_tls_version = "TLS1_2"
#   public_network_access_enabled = false

#   network_rules {
#     default_action = "Deny"
#     #virtual_network_subnet_ids = azurerm_subnet.sqlSubnet.id ## sql subnet
#   }
# }
# resource "azurerm_virtual_machine" "sql"{
#     storage_image_reference {
#     publisher = "MicrosoftSQLServer"
#     offer     = "SQL2017-WS2016"
#     sku       = "SQLDEV"
#     version   = "latest"
#   }
# }
# Create network interface for sql
resource "azurerm_network_interface" "iBeacon-nic2" {
  name                = "iBeacon-nic2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "iBeacon-nic"
    subnet_id                     = azurerm_subnet.sqlVmSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.iBeacon-pubIP2.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg2" {
  network_interface_id      = azurerm_network_interface.iBeacon-nic2.id
  network_security_group_id = azurerm_network_security_group.iBeacon-nsg.id
}

# Create storage account for boot diagnostics
# resource "azurerm_storage_account" "sqlsa" {
#   name                     = "diag${random_id.random_id.hex}"
#   location                 = azurerm_resource_group.rg.location
#   resource_group_name      = azurerm_resource_group.rg.name
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }

resource "azurerm_lb" "sqllb" { ## internal lb hence private IP
  name                = "sqllb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "sqllb_ip"
    subnet_id            = azurerm_subnet.sqlVmSubnet.id
    private_ip_address_allocation = "dynamic"
    # private_ip_address = ["10.0.2.0/24"]
  }
}

resource "azurerm_virtual_machine" "sql" {
  name                  = "sql"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.iBeacon-nic2.id]
  vm_size               = "Standard_DS1_v2"
 
  storage_os_disk {
    name              = "sql-OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    os_type = "Windows"
  }
  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "latest"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "sqllogin"
    admin_password = "Password1234!"
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }
  # boot_diagnostics {
  #   storage_account_uri = azurerm_storage_account.sqlsa.primary_blob_endpoint
  # }
}

# resource "azurerm_mssql_virtual_machine" "sqlVM"{
#   virtual_machine_id = azurerm_virtual_machine.sql.id
#   sql_license_type = "PAYG"
#   r_services_enabled = true # i think r language ?
#   sql_connectivity_port = 1433
#   sql_connectivity_type = "PRIVATE"
#   sql_connectivity_update_password = "Password1234!"  
#   sql_connectivity_update_username = "sqllogin"

#   auto_patching {
#     day_of_week = "Sunday"
#     maintenance_window_duration_in_minutes = 60
#     maintenance_window_starting_hour = 2
#   }
#   # auto_backup {
#   #   encryption_enabled = true
#   #   encryption_password = "Password1234!"
#   #   retention_period_in_days = 30 ## higher == more ££
#   #   storage_blob_endpoint = azurerm_storage_account.sqlsa.id
#   #   storage_account_access_key = "Key1234"
#   # }
# }

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "random_pet" "prefix" {
  prefix = var.prefix
  length = 1
}
