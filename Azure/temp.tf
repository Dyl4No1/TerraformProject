# some code inspiration from : 
# https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-terraform

#azure ad users : check user type  of "azuread_user"
#billing account ?

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

# Create Resource group for web vms
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "rg"                           #can use ${random_pet.prefix.id} for randomised name
}

resource "azurerm_network_ddos_protection_plan" "ddos" {
  name                = "${var.vnet_name}_DDOS_PLAN"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create virtual network with relevant address space
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_cidr
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_servers         = var.vnet_dns_servers
  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.ddos.id
    enable = true
  }
  dynamic "subnet" {
    for_each = var.subnets
    content {
      name             = subnet.key
      address_prefix = subnet.value.address_prefix
    }
  }
}
# private ip address ?
# Relies on var.subnets property nsg_name, if it exists
resource "azurerm_network_security_group" "nsgs" {
  for_each            = toset([for subnet in var.subnets : subnet.nsg_name if subnet.nsg_name != ""])
  location            = azurerm_resource_group.rg.location
  name                = each.value
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsgs_assoc" {
  for_each = toset([for subnet in var.subnets : subnet.nsg_name if subnet.nsg_name != ""])
  subnet_id                 = azurerm_virtual_network.vnet.subnet[each.value].id
  network_security_group_id = azurerm_network_security_group.nsgs[var.subnets[each.value].nsg_name].id
}


# Create network interface for web
resource "azurerm_network_interface" "iBeacon-nic" {
  name                = "iBeacon-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "iBeacon-nic"
    subnet_id                     = azurerm_virtual_network.vnet.subnet["webVmSubnet"].id 
    #toset([for subnet in azurerm_virtual_network.vnet.subnet: subnet.id if subnet.name != "webVmSubnet"])
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.vnet_gateway_pips[""].id
  }
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
  name                  = "webVM"
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

######## web lb
# resource "azurerm_public_ip" "iBeacon-pubIP3" {
#   name                = "iBeacon-pubIP3"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Dynamic"
# }

resource "azurerm_lb" "weblb" { ## external lb hence public IP
  name                = "weblb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dynamic "frontend_ip_configuration" {
    for_each = azurerm_public_ip.vnet_gateway_pips
    content{
      name                 = "${frontend_ip_configuration.value.name}_lb"
      public_ip_address_id = frontend_ip_configuration.value.id
      subnet_id = azurerm_virtual_network.vnet.subnet["GatewaySubnet"].id
      private_ip_address_allocation = "Dynamic"
    }
  }
}

# resource "azurerm_lb_backend_address_pool" "weblb_bap" {


# }
# resource "azurerm_lb_probe" "weblb_probe" {


# }
# resource "azurerm_lb_rule" "weblb_rule"{


# }
# resource "azurerm_network_interface_backend_address_pool_association" "weblb_nic" {

  
# }
 

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
resource "azurerm_public_ip" "vnet_gateway_pips" {
  count               = var.gateway_pip_count
  name                = "${var.gateway_name}-PIP-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1]
}

# Create network interface for sql
resource "azurerm_network_interface" "iBeacon-nic2" {
  name                = "iBeacon-nic2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "iBeacon-nic"
    subnet_id                     = azurerm_virtual_network.vnet.subnet["sqlVmSubnet"].id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.iBeacon-pubIP2.id
  }
}

# # Connect the security group to the network interface
# resource "azurerm_network_interface_security_group_association" "sg2" {
#   network_interface_id      = azurerm_network_interface.iBeacon-nic2.id
#   network_security_group_id = azurerm_network_security_group.iBeacon-nsg.id
# }

## SQL stuff
resource "azurerm_storage_account" "sqlsa" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_lb" "sqllb" { ## internal lb hence private IP
  name                = "sqllb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "sqllb_ip"
    subnet_id            = azurerm_virtual_network.vnet.subnet["sqlVmSubnet"].id
    private_ip_address_allocation = "Dynamic"
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
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.websa.primary_blob_endpoint
  }
}

############
#TO DO######
############

## route table for gcp conn (see "guide" by eduard https://taeduard.ro/Terraform-GCP-Azure-VPN/)
## Management group > subscription > resource group DONE (outside scope)
## vertical (hardware: upgrade) / horizontal(software: more effort + setup) scaling
## learn availability zones/sets NEEDS DOING
## LOAD BALANCERS !!! (out of scope )
## add firewall settings from discord HALF
## add mssql vm (attach database instance ?) WIP
## add storage pub and priv NEEDS DOING
## debug
## SCREENSHOTS HALF


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
