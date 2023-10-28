output "resource_group_name" {
  value = azurerm_resource_group.rgpy.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.my_terraform_vmpy.public_ip_address
}