variable "guid" {
  type = "string"
}


resource "azurerm_resource_group" "guidtest" {
  name     = "guidtest"
  location = "westeurope"
}

resource "azurerm_managed_disk" "guidtest" {
  name                 = "disk-${var.guid}"
  location             = "westeurop"
  resource_group_name  = "${azurerm_resource_group.guidtest.name}"
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = "128"
}