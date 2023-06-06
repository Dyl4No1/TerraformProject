## some code inspiration from:
## https://taeduard.ro/Terraform-GCP-Azure-VPN/
## compute engine api required to run
# projectID = "ibeacon-gcp-az-387103"

resource "google_compute_vpn_gateway" "azuretarget_gateway" {
    name = "aztarget-gw"
    network = google_compute_network.gcp-network.id
}
resource "google_compute_network" "gcp-network"{
    name = "gcp-network"
    project = "ibeacon-gcp-az-387103" #google_project.ibeacon-gcp.name
    auto_create_subnetworks = false
    routing_mode = "GLOBAL"
}

resource "google_compute_vpn_tunnel" "tunnel2azure" {
    name = "azurevpntunnel1"
    peer_ip = "20.234.187.179" # random ip so it can run
    shared_secret = "12345678"

    target_vpn_gateway = google_compute_vpn_gateway.azuretarget_gateway.id

    local_traffic_selector = ["0.0.0.0/0"]
    remote_traffic_selector = ["0.0.0.0/0"]
    
    # depends_on = [
    #     google_compute_forwarding_rule.fr_icmp
    # ]
}
resource "google_compute_route" "azroute" {
    name = "azroute"
    network = google_compute_network.gcp-network.name
    dest_range = "10.2.0.0/27" # only 27 works
    priority = 500

    next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel2azure.id
}

#hub?
# resource "google_compute_forwarding_rule" "fr_icmp" {
#     name = "fr-icmp"
#     ip_protocol = "TCP"
#     ip_address = "169.254.21.2" # azure vpn gateway
#     target = google_compute_vpn_gateway.azuretarget_gateway.id
#     #load_balancing_scheme = "INTERNAL_MANAGED"
# }

resource "google_compute_subnetwork" "gatewaysubnet" {
  name          = "gatewaysubnet"
  ip_cidr_range = "10.3.0.0/27" # must be 27 for gw
  network       = google_compute_network.gcp-network.id
  region        = "europe-west1"
}
resource "google_compute_subnetwork" "webvmsubnet" {
  name          = "webvmsubnet"
  ip_cidr_range = "10.3.1.0/24"
  network       = google_compute_network.gcp-network.id
  region        = "europe-west1"
}
resource "google_compute_subnetwork" "sqlvmsubnet" {
  name          = "sqlvmsubnet"
  ip_cidr_range = "10.3.2.0/24"
  network       = google_compute_network.gcp-network.id
  region        = "europe-west1"
}

## firewall rules
# Allow http
resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = google_compute_network.gcp-network.name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http"] 
}
# Allow https
resource "google_compute_firewall" "allow-https" {
  name    = "allow-https"
  network = google_compute_network.gcp-network.name
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["https"]
}
# allow rdp
resource "google_compute_firewall" "allow-rdp" {
  name    = "allow-rdp"
  network = google_compute_network.gcp-network.name
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["rdp"]
}
resource "google_compute_firewall" "allow-icmp" {
  name    = "allow-icmp"
  network = google_compute_network.gcp-network.name
  allow {
    protocol = "tcp"
    ports    = ["0"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["icmp"]
}

##vms
# web vm 
data "template_file" "windows-metadata" {
template = <<EOF
# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools;
EOF
}
resource "google_compute_instance" "webvm" {
    name = "webvm"
    machine_type = "e2-medium"
    zone = "europe-west1-b"

    boot_disk {
        initialize_params {
          image = "windows-cloud/windows-2022"
        }
    }
    scratch_disk { # local vm disk
        interface = "SCSI"
    }
    metadata = { # iis install
        sysprep-specialize-script-ps1 = data.template_file.windows-metadata.rendered
    }
    network_interface{
        network = google_compute_network.gcp-network.name
        subnetwork = google_compute_subnetwork.webvmsubnet.name
        access_config{}
    }
}
