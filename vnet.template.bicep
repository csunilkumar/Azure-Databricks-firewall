@description('The name of the virtual network to create.')
param hubVnetName string

@description('The name of the private subnet to create.')
param privatelinkSubnetName string = 'privatelink-subnet'

@description('Cidr range for the private link subnet..')
param privatelinkSubnetCidr string

@description('Cidr range for the spoke vnet.')
param hubVnetCidr string  

@description('Name of the virtual network hosting Azure Firewall, his VNet would be the hub.')
param hubSubnet1Name string = 'AzureFirewallSubnet'
param firewallSubnetCidr string 

@description('Name of the virtual network hosting Azure Firewall, his VNet would be the hub.')
param hubSubnet2Name string = 'clientDevices'
param hubSubnet2Cidr string 


@description('The name of the virtual network to create.')
param spoke1VnetName string

@description('Cidr range for the spoke vnet.')
param spoke1VnetCidr string 

@description('Cidr range for the private subnet.')
param privateSubnetName string = 'ADB_Private_subnet'
param privateSubnetCidr string 

@description('Cidr range for the public subnet.')
param publicSubnetName string = 'ADB_Public_subnet'
param publicSubnetCidr string 

@description('The name of the virtual network to create.')
param spoke2VnetName string

@description('Cidr range for the spoke vnet.')
param spoke2VnetCidr string 


@description('Network Location.')
param vnetLocation string = resourceGroup().location

@description('ServiceEndpoint Location.')
param serviceEndpointLocation string = resourceGroup().location

@description('Name of the Routing Table')
param routeTableName string

@description('The name of the existing network security group to create.')
param securityGroupName string


var securityGroupId = resourceId('Microsoft.Network/networkSecurityGroups', securityGroupName)


var serviceEndpoints = [
  {
    service: 'Microsoft.Storage'
    locations: [
      serviceEndpointLocation
    ]
  }
]


resource hubVnet_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: hubVnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetCidr
      ]
    }
    subnets: [
      {
        name: hubSubnet1Name
        properties: {
          addressPrefix: firewallSubnetCidr
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: hubSubnet2Name
        properties: {
          addressPrefix: hubSubnet2Cidr
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', routeTableName)
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}



resource spoke1Vnet_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: spoke1VnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke1VnetCidr
      ]
    }
    subnets: [
      {
        name: privateSubnetName
        properties: {
          addressPrefix: privateSubnetCidr
          networkSecurityGroup:{
            id:securityGroupId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', routeTableName)
          }
          serviceEndpoints: serviceEndpoints
          delegations: [
            {
              name: 'databricks-del-private'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: publicSubnetName
        properties: {
          addressPrefix: publicSubnetCidr
          networkSecurityGroup:{
            id:securityGroupId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', routeTableName)
          }
          delegations: [
            {
              name: 'databricks-del-public'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      
    ]
  }
}


resource spoke2Vnet_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: spoke2VnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke2VnetCidr
      ]
    }
    subnets: [
      {
        name: privatelinkSubnetName
        properties: {
          addressPrefix: privatelinkSubnetCidr
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: serviceEndpoints
          networkSecurityGroup:{
            id:securityGroupId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', routeTableName)
          }
          
        }
      }
    ]
  }
}

resource spoke1Vnet_Peer_SpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  parent: spoke1Vnet_resource
  name: 'Peer-Spoke1toHub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet_resource.id
    }
  }
}

resource spoke2Vnet_Peer_SpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  parent: spoke2Vnet_resource 
  name: 'Peer-Spoke2toHub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet_resource.id
    }
  }
}

resource HubSpoke_Peer_spoke2Vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  parent: hubVnet_resource 
  name: 'Peer-HubtoSpoke2'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spoke2Vnet_resource.id
    }
  }
}

resource HubSpoke_Peer_spoke1Vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  parent: hubVnet_resource 
  name: 'Peer-HubtoSpoke1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spoke1Vnet_resource.id
    }
  }
}


// output spoke_vnet_id string = spokeVnetName_resource.id
output privatelinksubnet_id string = resourceId('Microsoft.Network/virtualNetworks/subnets', spoke2VnetName, privatelinkSubnetName)
// output spoke_vnet_name string= spokeVnetName
output databricksPublicSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', spoke1VnetName, publicSubnetName)

output spoke1VnetName string = spoke1VnetName
output spoke2VnetName string = spoke2VnetName

output hubVnetName string = hubVnetName

output spoke1VnetId string = spoke1Vnet_resource.id
