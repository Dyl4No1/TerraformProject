## most of these are unused as they are experimental for a more complex
## broken prototype.thought it was worth uploading anyway se
## temp.tf for broken code.

## runtime variables
vnet_name        = "AZURE_NETWORK_A"
vnet_cidr        = ["10.2.0.0/16"]
vnet_dns_servers = ["8.8.8.8", "4.4.4.4"] ## google owned dns servers
vnet_ddos_protection = {
  enable = false
  id     = null
}

subnets = {
  GatewaySubnet = {
    address_prefix = "10.2.1.0/24"
    supports_udr   = false
  }
  webVmSubnet = {
    address_prefix = "10.2.2.0/24"
    nsg_name       = "webNSG"
    supports_udr   = false
  }
  sqlVmSubnet = {
    address_prefix = "10.2.3.0/24"
    nsg_name       = "sqlNSG"
    supports_udr   = false
  }
  lbSubnet = {
    address_prefix = "10.2.4.0/24"
    nsg_name       = "lbNSG"
    supports_udr   = false
  }
}

gateway_name          = "VPNGWHA"
gateway_pip_count     = 3
gateway_asn           = 65020 # Should be replaced with pipeline variables, or variable-groups from vault items
gateway_address_space = ["10.20.0.0/24"]
gateway_type          = "Vpn"
gateway_sku           = "VpnGw2AZ"
gateway_generation    = "Generation2"

