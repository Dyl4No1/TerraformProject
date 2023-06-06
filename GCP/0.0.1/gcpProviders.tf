terraform {
  required_version = ">=1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    google      = "~> 2.18.0"
    google-beta = "~> 2.18.0"
    
  }
}

provider "azurerm" {
  #subscription id  = {} for deploying to specific resource groups
  # for multiple specific, create new providerblock
  #
  #tenant_id = {}
  #client_id = {}
  #client_secret = {}
  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
provider "google" {
    #credentials = file(var.gcp_auth_file)
    #credentials = file("../project-instance/${var.gcp_auth_file}.json") #ibeacon-gcp-az-387103-2e35b572e450.json")
    region      = "${var.gcp_region}"
    project     = "ibeacon-gcp-az-387103"
}

provider "google-beta" {
    #credentials = file(var.gcp_auth_file)
    region      = "${var.gcp_region}"
    project     = "ibeacon-gcp-az-387103"
}