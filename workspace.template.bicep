@description('')
param adbWorkspaceName string = 'databricks${uniqueString(resourceGroup().id)}'
@description('')
param adbWorkspaceLocation string = resourceGroup().location
@description('')
param vnetName string = 'ADB_Spoke_VNet'


@allowed([
  'standard'
  'premium'
])
@description('')
param adbWorkspaceSkuTier string = 'standard'

@description('Name for the Private Subnet used for containers')
param publicSubnetName string = 'ADB_Public_subnet'
@description('Name for the Public Subnet used for VM to communicate')
param privateSubnetName string = 'ADB_Private_subnet'
@description('')
param disablePublicIp bool = true
@description('')
param tagValues object = {}


var managedResourceGroupName = 'databricks-rg-${adbWorkspaceName}-${uniqueString(adbWorkspaceName, resourceGroup().id)}'
var managedResourceGroupId = '${subscription().id}/resourceGroups/${managedResourceGroupName}'
var vnetId = resourceId('Microsoft.Network/virtualNetworks', vnetName)

resource adbWorkspaceName_resource 'Microsoft.Databricks/workspaces@2018-04-01' = {
  location: adbWorkspaceLocation
  name: adbWorkspaceName
  sku: {
    name: adbWorkspaceSkuTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
  }
  tags: tagValues
  dependsOn: []
}


output databricks_workspace_id string = adbWorkspaceName_resource.id
output databricks_workspaceUrl string = adbWorkspaceName_resource.properties.workspaceUrl
output databricks_dbfs_storage_accountName string = adbWorkspaceName_resource.properties.parameters.storageAccountName.value
