# Login to your Azure subscription
Login-AzureRmAccount
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
$resourceGroupName = Read-Host -Prompt "Enter the resource group name"
$location = Read-Host -Prompt "Enter the Azure region to create resources in"

# Create the resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

$defaultStorageAccountName = Read-Host -Prompt "Enter the name of the storage account"

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
$clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"

$httpUserName = "<userName>"
$httpPassword = "<password>"
$httpPW = ConvertTo-SecureString -String $httpPassword -AsPlainText -Force
$httpCredential = New-Object System.Management.Automation.PSCredential($httpUserName, $httpPW)

$sshUserName = "<userName>"
$sshPassword = "<password>"
$sshPW = ConvertTo-SecureString -String $sshPassword -AsPlainText -Force
$sshCredentials = New-Object System.Management.Automation.PSCredential($sshUserName, $sshPW)
# Default cluster size (# of worker nodes), version, type, and OS
$clusterSizeInNodes = 4
$headNodeSize = "Standard_D12_V2"
$workerNodeSize = "Standard_D13_V2"
$zookeeperNodeSize = "Standard_A1"
$clusterVersion = "3.6"
$clusterType = "SPARK" # INTERACTIVEHIVE or SPARK or ...
$clusterOS = "Linux"
$sshPublicKey = "<publicKey>" 
# Set the storage container name to the cluster name
$defaultBlobContainerName = $clusterName

# Create a blob container. This holds the default data store for the cluster.
New-AzureStorageContainer `
    -Name $defaultBlobContainerName -Context $defaultStorageContext

#$component = New-Object 'System.Collections.Generic.Dictionary[string, string]'
#$component.spark = "2.2"

# Create the HDInsight cluster
New-AzureRmHDInsightClusterConfig `
    -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net"  `
    -DefaultStorageAccountKey $defaultStorageAccountKey `
    -ClusterType $clusterType `
    -HeadNodeSize $headNodeSize `
    -WorkerNodeSize $workerNodeSize `
    -ZookeeperNodeSize $zookeeperNodeSize `
            | Add-AzureRmHDInsightComponentVersion `
                -ComponentName "Spark" `
                -ComponentVersion "2.2" `
            | New-AzureRmHDInsightCluster `
                -ResourceGroupName $resourceGroupName `
                -ClusterName $clusterName `
                -Location $location `
                -ClusterSizeInNodes $clusterSizeInNodes `
                -OSType $clusterOS `
                -Version $clusterVersion `
                -HttpCredential $httpCredential `
                -DefaultStorageContainer $defaultBlobContainerName `
                -SshCredential $sshCredentials `
                -SshPublicKey $sshPublicKey

####################################
# Verify the cluster
####################################
Get-AzureRmHDInsightCluster -ClusterName $clusterName