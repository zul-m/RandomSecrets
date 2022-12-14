resource "random_string" "username" {
  length  = 8
  special = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#%"
  min_numeric      = 1
  min_upper        = 1
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                        = "${var.infrastructure_id}kvt"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover",
    ]

    storage_permissions = [
      "Get", "List",
    ]
  }
}

resource "azurerm_key_vault_secret" "username" {
  name         = "admin-username"
  value        = random_string.username.result
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "password" {
  name         = "admin-password"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "vnet" {
  name         = "vnet-name"
  value        = "${var.infrastructure_id}vnet"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "nic" {
  name         = "vm-nic-name"
  value        = "${var.infrastructure_id}nic"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "vm" {
  name         = "vm-name"
  value        = "${var.infrastructure_id}vm"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "public_ip" {
  name         = "vm-public-ip-name"
  value        = "${var.infrastructure_id}ip"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "nsg" {
  name         = "vm-nsg-name"
  value        = "${var.infrastructure_id}nsg"
  key_vault_id = azurerm_key_vault.keyvault.id
}

# Create a public IP for the VM
resource "azurerm_public_ip" "vm_public_ip" {
  name                = azurerm_key_vault_secret.public_ip.value
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
}

# Save the public IP in the key vault
resource "azurerm_key_vault_secret" "public_ip_address" {
  name         = "vm-public-ip-address"
  value        = azurerm_public_ip.vm_public_ip.ip_address
  key_vault_id = azurerm_key_vault.keyvault.id
}