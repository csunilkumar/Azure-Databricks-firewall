@minLength(3)
@maxLength(24)
@description('Name of the storage account')
param storageAccountName string
param storageContainerName string = 'data'
param databricksPublicSubnetId string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
@description('Storage Account Sku')
param storageAccountSku string = 'Standard_LRS'

@description('Enable or disable Blob encryption at Rest.')
param encryptionEnabled bool =true

var storageLocation = resourceGroup().location 


//VirtualNetworkRules element in networkAcls property controls the network restriction, List all the virtual network subnets that are allowed to access this storage. 
// https://azsec.azurewebsites.net/2021/06/20/notes-in-azure-storage-network-restriction/
resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: storageLocation
  kind: 'StorageV2'
  properties:{
    isHnsEnabled:true
    minimumTlsVersion:'TLS1_2'
    supportsHttpsTrafficOnly:true
    accessTier:'Hot'
    networkAcls:{ 
      bypass:'AzureServices'
      virtualNetworkRules:[
        {
          id:databricksPublicSubnetId
          action:'Allow'
          state:'succeeded'
        }
      ]
      ipRules:[]
      defaultAction:'Deny'
    }
    encryption:{
      keySource:'Microsoft.Storage'
      services: {
        blob: {
          enabled: encryptionEnabled
        }
        file: {
          enabled: encryptionEnabled
        }
      }
    }
  }
  sku: {
    name: storageAccountSku
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName_resource.name}/default/${storageContainerName}'
}


var keysObj = listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2021-04-01')
output key1 string = keysObj.keys[0].value
output key2 string = keysObj.keys[1].value
output storageaccount_id string = storageAccountName_resource.id
// output container_obj object = container.properties
