variable "guid" {
  type = "string"
  description = "Generated Customer Usage Attribution GUID"
}

variable "test" {
    type = "string"
    description = "Test number"
}

data "azurerm_resource_group" "guidtest" {
  name     = "guidtest"
}

resource "azurerm_managed_disk" "guidtest" {
  name                 = "test${var.test}-${var.guid}"
  location             = "westeurope"
  resource_group_name  = "${azurerm_resource_group.guidtest.name}"
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = "128"
}