resource "random_pet" "ssh_key_namepy" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource_action" "ssh_public_key_genpy" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_namepy.id
  location  = azurerm_resource_group.rgpy.location
  parent_id = azurerm_resource_group.rgpy.id
}

output "key_data" {
  value = jsondecode(azapi_resource_action.ssh_public_key_genpy.output).publicKey
}