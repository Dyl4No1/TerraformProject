variable "resource_group_location" {
  default     = "westeurope"
  description = "Location of the resource group."
}

variable "prefix" {
  type        = string
  default = "win-vm-iis-vm"   #set default vm type
  description = "Prefix of the resource name"
}

# variable "sqllb_privIP" {} # empty args to demand input on run.