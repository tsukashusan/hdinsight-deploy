$resourceGroupName = "<resourceGroupName>"
$location = @("southeastasia", "japanwest", "japaneast")[2]
$defaultStorageAccountName = "<defaultStorageAccountName>"
$clusterName = "<clusterName>"
$clusterTypes = @("HADOOP", "SPARK", "INTERACTIVE", "STORM", "KAFKA")
$sshPublicKey = "<sshPublicKey>"
$vnetResourceGroupName = "<vnetResourceGroupName>"
$kafkaSubnetAddress = "<kafkaSubnetAddress>"
$kafkaSubnetName = "<kafkaSubnetName>"
$hdiotVirtualNetwork = "<hdiotVirtualNetwork>"

# Login to your Azure subscription
#Login-AzureRmAccount
# Is there an active Azure subscription?
$sub = Get-AzureRmSubscription -ErrorAction SilentlyContinue
if(-not($sub))
{
    Add-AzureRmAccount
}

# If you have multiple subscriptions, set the one to use
# $subscriptionID = "<subscription ID to use>"
# Select-AzureRmSubscription -SubscriptionId $subscriptionID

# Get user input/default values
if ( [String]::IsNullOrEmpty($resourceGroupName) )
{
    $resourceGroupName = Read-Host -Prompt "Enter the resource group name"
}

if ( [String]::IsNullOrEmpty($location) )
{
    $location = Read-Host -Prompt "Enter the Azure region to create resources in"
}

if ( [String]::IsNullOrEmpty($defaultStorageAccountName) )
{
   $defaultStorageAccountName = Read-Host -Prompt "Enter the name of the storage account"
}

# Create Subnet to VirtualNetwork
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $hdiotVirtualNetwork -ResourceGroupName $vnetResourceGroupName
Add-AzureRmVirtualNetworkSubnetConfig -Name $kafkaSubnetName `
    -VirtualNetwork $virtualNetwork -AddressPrefix $kafkaSubnetAddress
$virtualNetwork = Set-AzureRmVirtualNetwork -VirtualNetwork $virtualNetwork
$kafkaSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $kafkaSubnetName -VirtualNetwork $virtualNetwork

# Create the resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Create an Azure storae account and container
New-AzureRmStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $defaultStorageAccountName `
    -SkuName "Standard_LRS" `
    -Location $location
$defaultStorageAccountKey = (Get-AzureRmStorageAccountKey `
                                -ResourceGroupName $resourceGroupName `
                                -Name $defaultStorageAccountName)[0].Value
$defaultStorageContext = New-AzureStorageContext `
                                -StorageAccountName $defaultStorageAccountName `
                                -StorageAccountKey $defaultStorageAccountKey

# Get information for the HDInsight cluster

# Cluster login is used to secure HTTPS services hosted on the cluster
#$httpCredential = Get-Credential -Message "Enter Cluster login credentials" -UserName "admin"
# SSH user is used to remotely connect to the cluster using SSH clients
#$sshCredentials = Get-Credential -Message "Enter SSH user credentials"

$httpUserName = "admin"
$httpPassword = "<httpPassword>"
$httpPW = ConvertTo-SecureString -String $httpPassword -AsPlainText -Force
$httpCredential = New-Object System.Management.Automation.PSCredential($httpUserName, $httpPW)

$sshUserName = "sshuser"
$sshPassword = "<sshPassword>"
$sshPW = ConvertTo-SecureString -String $sshPassword -AsPlainText -Force
$sshCredentials = New-Object System.Management.Automation.PSCredential($sshUserName, $sshPW)

# Default cluster size (# of worker nodes), version, type, and OS
$clusterSizeInNodes = 4
$headNodeSize = "Standard_D3_V2"
$workerNodeSize = "Standard_D3_V2"
$zookeeperNodeSize = "Standard_A1"
$clusterVersion = "3.6"
$clusterType = $clusterTypes[4]
$clusterOS = "Linux"
if ( [String]::IsNullOrEmpty($sshPublicKey) )
{
    exit 1
}
# Set the storage container name to the cluster name
$defaultBlobContainerName = $clusterName

# Create a blob container. This holds the default data store for the cluster.
New-AzureStorageContainer `
    -Name $defaultBlobContainerName -Context $defaultStorageContext 

# Create the HDInsight cluster (Kafka)

$hdinsightConfig = New-AzureRmHDInsightClusterConfig `
    -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net"  `
    -DefaultStorageAccountKey $defaultStorageAccountKey `
    -ClusterType $clusterType `
    -HeadNodeSize $headNodeSize `
    -WorkerNodeSize $workerNodeSize `
    -ZookeeperNodeSize $zookeeperNodeSize

$kafkaSubnet

New-AzureRmHDInsightCluster `
        -ResourceGroupName $resourceGroupName `
        -ClusterName $clusterName `
        -Location $location `
        -ClusterSizeInNodes $clusterSizeInNodes `
        -OSType $clusterOS `
        -Version $clusterVersion `
        -HttpCredential $httpCredential `
        -DefaultStorageContainer $defaultBlobContainerName `
        -SshCredential $sshCredentials `
        -SshPublicKey $sshPublicKey `
        -Config $hdinsightConfig `
        -DisksPerWorkerNode 2 `
        -VirtualNetworkId $virtualNetwork.Id `
        -SubnetName $kafkaSubnet.Id `

$templateParameterObject = @{clusterName = $clusterName; _artifactsLocation = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-hdinsight-linux-add-edge-node/"; _artifactsLocationSasToken = ""; installScriptAction = "EmptyNodeSetup.sh"}
New-AzureRmResourceGroupDeployment -Name "edgeDeploy" `
    -ResourceGroupName $resourceGroupName `
    -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/101-hdinsight-linux-add-edge-node/azuredeploy.json `
    -TemplateParameterObject $templateParameterObject

####################################
# Verify the cluster
####################################
Get-AzureRmHDInsightCluster -ClusterName $clusterName

