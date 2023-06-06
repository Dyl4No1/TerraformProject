# Configure the GCP provider
provider "google" {
  credentials = file("<path-to-your-service-account-json>")
  project     = "<your-project-id>"
  region      = "<your-preferred-region>"
}

# Create the virtual network
resource "google_compute_network" "my_network" {
  name                    = "my-network"
  auto_create_subnetworks = false
}

# Create the subnets
resource "google_compute_subnetwork" "gateway_subnet" {
  name          = "gateway-subnet"
  network       = google_compute_network.my_network.self_link
  ip_cidr_range = "10.3.0.0/24"
}

resource "google_compute_subnetwork" "web_subnet" {
  name          = "web-vm-subnet"
  network       = google_compute_network.my_network.self_link
  ip_cidr_range = "10.3.1.0/24"
}

resource "google_compute_subnetwork" "sql_subnet" {
  name          = "sql-vm-subnet"
  network       = google_compute_network.my_network.self_link
  ip_cidr_range = "10.3.2.0/24"
}

# Create the VPN gateway
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "my-vpn-gateway"
  network = google_compute_network.my_network.self_link
}

# Create the VPN tunnel
resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name               = "my-vpn-tunnel"
  peer_ip            = "169.254.21.2"
  shared_secret      = "12345678"
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.self_link
  vpn_gateway_interface = "vpn_gateway_interface"
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]
}

# Create the route table
resource "google_compute_route_table" "my_route_table" {
  name    = "my-route-table"
  network = google_compute_network.my_network.self_link

  route {
    name               = "default-route"
    destination_range  = "0.0.0.0/0"
    next_hop_gateway   = google_compute_vpn_gateway.vpn_gateway.self_link
  }
}

# Associate the route table with subnets
resource "google_compute_subnetwork" "GatewaySubnet" {
  name          = "GatewaySubnet"
  network       = google_compute_network.my_network.self_link
  ip_cidr_range = "10.3.0.0/24"

  secondary_ip_range {
    range_name    = "GatewaySubnet-range"
    ip_cidr_range = "10.3.0.0/24"
  }

  log_config {
    enable = false
  }

  depends_on = [google_compute_route_table.my_route_table]
}

resource "google_compute_subnetwork" "webVmSubnet" {
  name          = "webVmSubnet"
  network       = google_compute_network.my_network.self_link
  ip_cidr_range = "10.3.1.0/24"

  secondary_ip_range {
    range_name    = "webVmSubnet-range"
    ip_cidr_range = "10.3.1.0/24"
  }

  log_config {
    enable = false
  }
    depends_on = [google_compute_route_table.my_route_table]
}