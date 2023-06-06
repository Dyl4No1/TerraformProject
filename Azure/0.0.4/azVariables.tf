## like with azMain.tfvars, most of these are unused and are used in a 
## more complex solution with far better practices.
## see temp.tf for main file.

## variables

variable "resource_group_location" {
  default     = "westeurope"
  description = "Location of the resource group."
}

variable "prefix" {
  type        = string
  default     = "win-vm-iis-vm"
  description = "Prefix of the resource name"
}

##
variable "vnet_name" {
  description = "Name of the vnet to create"
  type        = string
  default     = "vnet"
}
variable "vnet_cidr" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
  default     = ["10.2.0.0/16"]
}
variable "vnet_dns_servers" {
  description = "The DNS servers to be used with vNet."
  type        = list(string)
  default     = []
}
variable "vnet_ddos_protection" {
  description = "The set of DDoS protection plan configuration"
  type = object({
    enable = bool
    id     = string
  })
  default = null
}

##
variable "gateway_pip_count" {
  type    = number
  default = 2
  #3 = ha appliances only: uses 1,2 for primary and secondary, and 3 is used for azure mgmt api calls
}
variable "gateway_name" {
  type    = string
  default = "vpngw01"
}
variable "gateway_subnet" {
  description = "The address prefix to use for the subnet."
  type        = list(string)
  default     = ["10.2.0.0/27"]
}
variable "gateway_asn" {
  type    = number
  default = "65002"
}
variable "gateway_address_space" {
  description = "The address ranged to use by the OPENVPN/SSLVPN Clients"
  type        = list(string)
  default     = ["10.20.2.0/23"]
}
variable "gateway_type" {
  type    = string
  default = "Vpn"
}
variable "gateway_sku" {
  type    = string
  default = "VpnGw2"
  #GW2s are usually highly available
}
variable "gateway_generation" {
  type    = string
  default = "Generation2"
}

variable "subnets" {
  type = map(
    object({
      name              = string
      address_prefix    = string
      supports_udr      = optional(bool, true)
      nsg_name          = optional(string, "")
      service_endpoints = optional(list(string), [])
      delegation = optional(
        object({
          name    = string
          actions = list(string)
        })
      )
      enforce_private_link_endpoint_network_policies = optional(bool, null)
      enforce_private_link_service_network_policies  = optional(bool, null)
    })
  )
  default = {
    0 = {
      name           = "GatewaySubnet"
      address_prefix = "10.2.0.0/24"
    }
    1 = {
      name           = "AzureBastionSubnet"
      address_prefix = "10.2.1.0/24"
    }
    2 = {
      name           = "AppGWFrontend"
      address_prefix = "10.2.2.0/24"
    }
    3 = {
      name           = "AppGWBackend"
      address_prefix = "10.2.3.0/24"

    }
    4 = {
      name              = "Subnet1"
      address_prefix    = "10.0.4.0/24"
      service_endpoints = ["Microsoft.AzureCosmosDB", "Microsoft.ContainerRegistry"]
      delegation = {
        name    = "Microsoft.ContainerInstance/containerGroups"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}


# variable "sqllb_privIP" {} # empty args to demand input on run.