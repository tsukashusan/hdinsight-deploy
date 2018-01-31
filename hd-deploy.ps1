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
    -Type Standard_LRS `
    -Location $location
$defaultStorageAccountKey = (Get-AzureRmStorageAccountKey `
                                -ResourceGroupName $resourceGroupName `
                                -Name $defaultStorageAccountName)[0].Value
$defaultStorageContext = New-AzureStorageContext `
                                -StorageAccountName $defaultStorageAccountName `
                                -StorageAccountKey $defaultStorageAccountKey

# Get information for the HDInsight cluster
$clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"
# Cluster login is used to secure HTTPS services hosted on the cluster
$httpCredential = Get-Credential -Message "Enter Cluster login credentials" -UserName "admin"
# SSH user is used to remotely connect to the cluster using SSH clients
$sshCredentials = Get-Credential -Message "Enter SSH user credentials"

# Default cluster size (# of worker nodes), version, type, and OS
$clusterSizeInNodes = 4
$headNodeSize = "Standard_D13_V2"
$workerNodeSize = "Standard_D14_V2"
$zookeeperNodeSize = "Standard_A1"
$clusterVersion = "3.6"
$clusterType = "INTERACTIVEHIVE" # INTERACTIVEHIVE or spark or ...
$clusterOS = "Linux"
$sshPublicKey = "<public key>" 
# Set the storage container name to the cluster name
$defaultBlobContainerName = $clusterName

# Create a blob container. This holds the default data store for the cluster.
New-AzureStorageContainer `
    -Name $clusterName -Context $defaultStorageContext 

# Create the HDInsight cluster
New-AzureRmHDInsightCluster `
    -ResourceGroupName $resourceGroupName `
    -ClusterName $clusterName `
    -Location $location `
    -ClusterSizeInNodes $clusterSizeInNodes `
    -HeadNodeSize $headNodeSize `
    -WorkerNodeSize $workerNodeSize `
    -ZookeeperNodeSize $zookeeperNodeSize `
    -ClusterType $clusterType `
    -OSType $clusterOS `
    -Version $clusterVersion `
    -HttpCredential $httpCredential `
    -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net" `
    -DefaultStorageAccountKey $defaultStorageAccountKey `
    -DefaultStorageContainer $clusterName `
    -SshCredential $sshCredentials `
    -SshPublicKey $sshPublicKey
