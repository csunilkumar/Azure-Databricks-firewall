//Reference : https://techcommunity.microsoft.com/t5/fasttrack-for-azure/using-azure-firewall-as-a-network-virtual-appliance-nva/ba-p/1972934


targetScope = 'subscription'

@minLength(2)
@maxLength(4)
@description('2-4 chars ONLY to prefix the Azure Resources, DO NOT use number or symbol')
param prefix string = 'kkc'
var uniqueSubString = '${uniqueString(guid(subscription().subscriptionId))}'
var uString = '${prefix}${uniqueSubString}'

var resourceGroupName = '${substring(uString, 0, 6)}-rg'

var storageAccountName = '${substring(uString, 0, 10)}stg01'

// inputs for  nsg.template.bicep
var nsgName = '${substring(uString, 0, 6)}-nsg'

var firewallName = '${substring(uString, 0, 6)}-HubFW'
var firewallPublicIpName = '${substring(uString, 0, 6)}-FWPIp'

// inputs for  routetable.template.bicep
var fwRoutingTable = '${substring(uString, 0, 6)}-AdbRoutingTbl'


@description('')
param HubVnetName string = 'hubvnet'
param HubSubnet2Name string = 'FEVMS'
param HubVNetCidr string = '10.200.0.0/16'
param FirewallSubnetCidr string = '10.200.0.0/18'
param HubSubnet2Cidr string = '10.200.64.0/18'

param SpokeVnetCidr string = '10.201.0.0/16'
param PublicSubnetCidr string = '10.201.64.0/18'
param PrivateSubnetCidr string = '10.201.0.0/18' 


param Spoke2VnetCidr string = '10.202.0.0/16'
param PrivateLinkSubnetCidr string = '10.202.64.0/18'


@description('Default location of the resources')
param location string = 'westus2'
  
@description('westus2 ADB webapp address')
param webappDestinationAddresses array = [
  '40.118.174.12/32'
]

@description('westus2 ADB log blob')
param logBlobstorageDomains array = [
  'dblogprodwestus.blob.${environment().suffixes.storage}'
  'dblogprodwestus2.blob.${environment().suffixes.storage}'
]
@description('westus ADB extended ip')
param extendedInfraIp array = [
  '13.91.84.96/28'
]
@description('westus2 SCC relay Domain')
param sccReplayDomain array = [
  'tunnel.westus.azuredatabricks.net'
]
@description('westus2 SDB metastore')
param metastoreDomains array = [
  'consolidated-westus2-prod-metastore.mysql.database.azure.com'
  'consolidated-westus2-prod-metastore-addl-1.mysql.database.azure.com'
  'consolidated-westus2-prod-metastore-addl-2.mysql.database.azure.com'
]
@description('westus2 EventHub endpoint')
param eventHubEndpointDomain array = [
  'prod-westus-observabilityeventhubs.servicebus.windows.net'
]
@description('westus2 EventHub endpoint')
param bootStrap array = [
  'westus.azuredatabricks.net'
  'dbartifactsprodwestus.${environment().suffixes.storage}'
  'arprodwestusa5.${environment().suffixes.storage}'
  'arprodwestusa2.${environment().suffixes.storage}'

]
@description('westus2 Artifacts Blob')
param artifactBlobStoragePrimaryDomains array = [
  'dbartifactsprodwestus2.blob.${environment().suffixes.storage}'
  'arprodwestus2a1.blob.${environment().suffixes.storage}'
  'arprodwestus2a2.blob.${environment().suffixes.storage}'
  'arprodwestus2a3.blob.${environment().suffixes.storage}'
  'arprodwestus2a4.blob.${environment().suffixes.storage}'
  'arprodwestus2a5.blob.${environment().suffixes.storage}'
  'arprodwestus2a6.blob.${environment().suffixes.storage}'
]


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  }

module routeTable 'routetable.template.bicep' = {
  scope: rg
  name: 'RouteTableTempate'
  params: {
    routeTableName: fwRoutingTable 
    routeTableLocation:location  
  }
}

module nsg 'nsg.template.bicep' = {
  scope: rg
  name: 'NetworkSecurityGroup'
  params: {
    securityGroupName : nsgName
    nsgLocation:location
  }
 }

 module vnets 'vnet.template.bicep' = {
  scope: rg
  name: 'HubandSpokeVnets'
  params: {
    vnetLocation : location
    hubVnetName : HubVnetName
    hubVnetCidr: HubVNetCidr
    firewallSubnetCidr: FirewallSubnetCidr

    hubSubnet2Name: HubSubnet2Name
    hubSubnet2Cidr: HubSubnet2Cidr

    spoke1VnetName : 'ADB_Spoke_VNet'
    spoke1VnetCidr: SpokeVnetCidr
    privateSubnetCidr: PrivateSubnetCidr    
    publicSubnetCidr: PublicSubnetCidr
   
   
    spoke2VnetName : 'shared-infra-vnet'
    spoke2VnetCidr: Spoke2VnetCidr
    privatelinkSubnetName: 'privatelink-subnet'
    privatelinkSubnetCidr:PrivateLinkSubnetCidr

                 
    serviceEndpointLocation: location 
    securityGroupName : nsg.outputs.nsgName
    routeTableName : routeTable.outputs.routeTblName

  }
 }

module routeTableUpdate 'firewallroute.template.bicep' = {
  scope: rg
  name: 'RouteTableUpdate'
  params: {
    routeTableName: fwRoutingTable
    firewallPrivateIp: hubFirewall.outputs.firewallPrivateIp
  }
}

module workspace 'workspace.template.bicep' = {
  scope: rg
  name: 'adbworkspace'
  params: {
    vnetName : vnets.outputs.spoke1VnetName
    adbWorkspaceLocation : location
  }
 }


module hubFirewall 'firewall.template.bicep' = {
  scope: rg
  name: 'HubFirewall'
  params: {
    firewallName: firewallName
    publicIpAddressName: firewallPublicIpName
    vnetName: vnets.outputs.hubVnetName
    firewallLocation : location
    webappDestinationAddresses: webappDestinationAddresses
    logBlobstorageDomains: logBlobstorageDomains
    infrastructureDestinationAddresses: extendedInfraIp
    sccRelayDomains: sccReplayDomain
    metastoreDomains: metastoreDomains
    eventHubEndpointDomains: eventHubEndpointDomain
    artifactBlobStoragePrimaryDomains: artifactBlobStoragePrimaryDomains
    
    dbfsBlobStrageDomain: array('${workspace.outputs.databricks_dbfs_storage_accountName}.blob.${environment().suffixes.storage}')
   }
}

module adlsGen2 'storageaccount.template.bicep' = {
  scope: rg
  name: 'StorageAccount'
  params: {
    storageAccountName: storageAccountName
    databricksPublicSubnetId: vnets.outputs.privatelinksubnet_id
  }
}

module privateEndPoints 'privateendpoint.template.bicep' = {
  scope: rg
  name: 'PrivateEndPoints'
    params: {
     privateLinkLocation: location  
    privateLinkSubnetId: vnets.outputs.privatelinksubnet_id
    vnetName: vnets.outputs.spoke2VnetName
    storageAccountName: adlsGen2.name
    storageAccountPrivateLinkResource:adlsGen2.outputs.storageaccount_id
  }
}

