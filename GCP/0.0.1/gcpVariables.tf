variable "project_location" {
  default     = "westeurope"
  description = "Location of the resource group."
}

# inspiration from:
#https://gmusumeci.medium.com/how-to-deploy-a-windows-server-vm-instance-in-gcp-using-terraform-2186fc8ac25b
#GCP authentication file
variable "gcp_auth_file" {
  type        = string
  description = "GCP authentication file"
}
# define GCP region
variable "gcp_region" {
  type        = string
  description = "GCP region"
}
#define GCP project name
# variable "gcp_project" {
#   type        = string
#   description = "GCP project name"
# }