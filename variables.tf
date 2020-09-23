variable "location" {}

variable "computer_name" {
  type = string
  description = "Name of the computer"
}

variable "admin_username" {
  type        = string
  description = "Administrator user name for virtual machine"
}

variable "admin_password" {
  type        = string
  description = "Password must meet Azure complexity requirements"
}

variable "prefix" {
  type    = string
  default = "ops"
}

variable "tags" {
  type = map

  default = {
    "Owner" = "Oaker"
    "Purpose" = "PersonalComputer"
    "Department" = "ReliabilityEngineering"
  }
}

variable "sku" {
  default = {
    southeastasia = "19h2-pro"
    eastasia = "19h1-pro"
  }
}
