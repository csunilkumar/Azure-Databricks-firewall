@description('Storage Account Privatelink Resource')
param storageAccountPrivateLinkResource string

@description('Storage Account name')
param storageAccountName string
var Privateendpoint_blobstorage_name = '${toLower(storageAccountName)}-blob-Privateendpoint'

@description('Vnet name for private link')
param vnetName string

@description('Complete Subnet to which this storage will be available externally, Ex : /subscription/guid/RG/..')
param privateLinkSubnetId string

@description('Privatelink subnet Id')
param privateLinkLocation string = resourceGroup().location

var privateDnsNameStorageBlob_var = 'privatelink.blob.${environment().suffixes.storage}'

resource blobStorageAccountPrivateEndpoint_resource 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: Privateendpoint_blobstorage_name
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: Privateendpoint_blobstorage_name
        properties: {
          privateLinkServiceId: storageAccountPrivateLinkResource
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}

resource privateDnsNameStorageBob_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameStorageBlob
  name: 'file_link_to_${toLower(vnetName)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}


resource privateDnsNameStorageBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameStorageBlob_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    blobStorageAccountPrivateEndpoint_resource
  ]
}


resource storageAccountBlobPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: blobStorageAccountPrivateEndpoint_resource
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameStorageBlob.id
        }
      }
    ]
  }
}
