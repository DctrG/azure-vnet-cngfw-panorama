terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "1.11.1"
    }
  }
}

provider "panos" {
  hostname = var.panorama_ip
  username = var.panorama_username
  password = var.panorama_password
}

data "terraform_remote_state" "cngfw" {
  backend = "local"
  config = {
    path = "../terraform.tfstate"
  }
}

resource "panos_panorama_template_stack" "cngfw_azure_template_stack" {
    name = var.template_stack

    lifecycle {
        create_before_destroy = true
    }
}

resource "panos_panorama_log_forwarding_profile" "cngfw-logging" {
  name = var.log_forwarding_profile
  device_group = var.device_group
  enhanced_logging = true
  match_list {
    name = "traffic"
    log_type = "traffic"
    send_to_panorama = true
  }

  lifecycle {
    create_before_destroy = true
    }
}

resource "panos_security_rule_group" "panorama-policies" {
  device_group  = var.device_group
  
   rule {
    name                  = "Allow apt-get from Linux VMs"
    source_zones          = ["Private"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["Public"]
    destination_addresses = ["any"]
    applications          = ["apt-get"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = panos_panorama_log_forwarding_profile.cngfw-logging.name
  }

     rule {
    name                  = "Allow Destination NAT"
    source_zones          = ["Public"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["Private"]
    #destination_addresses = [data.terraform_remote_state.cngfw.outputs.cngfw-pip]
    destination_addresses = ["any"]
    applications          = ["web-browsing"]
    services              = ["service-http"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = panos_panorama_log_forwarding_profile.cngfw-logging.name
  }

   rule {
    name                  = "East-West web-browsing Allowed"
    source_zones          = ["Private"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["Private"]
    destination_addresses = ["any"]
    applications          = ["web-browsing"]
    services              = ["service-http"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = panos_panorama_log_forwarding_profile.cngfw-logging.name
  }

   rule {
    name                  = "Explicit Deny All"
    source_zones          = ["any"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "deny"
    log_setting           = panos_panorama_log_forwarding_profile.cngfw-logging.name
  }

  lifecycle { create_before_destroy = true }
}