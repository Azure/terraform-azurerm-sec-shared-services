provider "azurerm" {
  version = "~>2.0"
  features {}
}

locals {
  suffix                  = concat(["ss"], var.suffix)
  resource_group_location = var.resource_group_location
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming"
  suffix = local.suffix
}

module "virtual_network" {
  source                      = "./shared_services_networking"
  virtual_network_cidr        = var.virtual_network_cidr
  suffix                      = local.suffix
  use_existing_resource_group = var.use_existing_resource_group
  resource_group_name         = var.resource_group_name
  resource_group_location     = local.resource_group_location
  firewall_public_ip_sku      = var.firewall_public_ip_sku
}

module "audit_diagnostics_package" {
  source                                     = "git::https://github.com/Azure/terraform-azurerm-sec-audit-diagnostics-package"
  storage_account_private_endpoint_subnet_id = module.virtual_network.audit_subnet.id
  use_existing_resource_group                = false
  resource_group_location                    = local.resource_group_location
  suffix                                     = local.suffix
  event_hub_namespace_sku                    = "Standard"
  event_hub_namespace_capacity               = "1"
  event_hubs = {
    "eh-ss" = {
      name              = module.naming.eventhub.name
      partition_count   = 1
      message_retention = 1
      authorisation_rules = {
        "ehra-ap" = {
          name   = module.naming.eventhub_authorization_rule.name
          listen = true
          send   = true
          manage = true
        }
      }
    }
  }
  log_analytics_workspace_sku           = "PerGB2018"
  log_analytics_retention_in_days       = var.log_retention_duration
  automation_account_alternate_location = local.resource_group_location
  automation_account_sku                = "Basic"
  storage_account_name                  = module.naming.storage_account.name_unique
  storage_account_tier                  = "Standard"
  storage_account_replication_type      = "LRS"

  #TODO: Work out what additional if any allowed ip ranges and permitted virtual network subnets there needs to be.

  allowed_ip_ranges                    = concat([], var.authorised_audit_client_ips)
  permitted_virtual_network_subnet_ids = concat([], var.authorised_audit_subnet_ids)
  bypass_internal_network_rules        = true
}

module "security_package" {
  source                               = "git::https://github.com/Azure/terraform-azurerm-sec-security-package"
  use_existing_resource_group          = false
  resource_group_location              = local.resource_group_location
  key_vault_private_endpoint_subnet_id = module.virtual_network.secrets_subnet.id
  suffix                               = local.suffix

  #TODO: Work out what additional if any allowed ip ranges and permitted virtual network subnets there needs to be.

  allowed_ip_ranges                    = concat([], var.authorised_security_client_ips)
  permitted_virtual_network_subnet_ids = concat([], var.authorised_security_subnet_ids)
  sku_name                             = "standard"
  enabled_for_deployment               = true
  enabled_for_disk_encryption          = true
  enabled_for_template_deployment      = true
}

/* module "log_definition" {
  source = "git::https://github.com/Nepomuceno/terraform-azurerm-monitoring-policies.git"
} */