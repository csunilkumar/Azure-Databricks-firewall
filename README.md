# Deploy secure Azure Databricks cluster with Data exfiltration using [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview).

Based on the baseline of best practices deatailed in  [Data Exfiltration Protection with Azure Databricks](https://databricks.com/blog/2020/03/27/data-exfiltration-protection-with-azure-databricks.html)

# To Do
- Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)
- Install [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- Better to use VS Code with bicep extension [instructions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- Clone the repo or download this repo, change into the repository directory using cd.

## Note

- By default location is set to West US 2 region in `main.bicep` file, changing the region would need to update the URD configuration in the `main.bicep` file
`@description('Default location of the resources')
param location string = 'westus2'`
- To create multiple environments in same subscription change the following string in main.bicep file, that would recreate all entities in a new resource group and the services will be prefixed with this string
`param prefix string = 'kkc'`

# How to use

- From the command prompt run: 
`az login`
- Recommend setting to use a specific subscription to avoid surprises:
`az account set -s "subscriptionID"
- Command to run the Bicep main deployment file, if successful that should create all the Azure Service listed in the table below.
`az deployment sub create \
    --location "westus2" \
    --template-file main.bicep `
    
    
| Name |Type |Description|
|--|--|--|
|ADB_Spoke_VNet|	Virtual network	|This Vnet would host the Azure Databricks Cluster, contains 2 subnets |
|databricksuldupgcah4nd2|	Azure Databricks Service|	Azure Databricks Workspace|
|hubvnet|	Virtual network|	This VNET would host the firewall|
|hubvnet-FEVMS-nsg-westus2	|Network security group|	NSG for Hub|
|kkcr6l-AdbRoutingTbl	|Route table	|Route Table containing a route to forward all request to the firewall|
|kkcr6l-FWPIp|	Public IP address|	Assigned to the firewall|
|kkcr6l-HubFW|	Firewall|	Firewall that blocks all the request, execept the one defind in the Rules|
|kkcr6l-nsg|	Network security group|	NSG for Hub|
|kkcr6lawtgstg01|	Storage account	|External Storage, connected to a shared VNET using private link|
|privatelink.blob.core.windows.net	|Private DNS zone|	Private link for the storage|
|shared-infra-vnet	|Virtual network|	VNET that would host all the share infra like SQL DB, Additional Storaged|
|storageaccount-blob-Privateendpoint|	Private endpoint	|
|storageaccount-blob-Privateendpoint.nic.e6836851-ba65-46ca-b5bc-4902a32b0841	|Network Interface	NIC for the private endpoint|

