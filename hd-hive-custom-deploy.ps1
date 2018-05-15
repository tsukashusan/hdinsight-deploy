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

$jarStorageAccountName = Read-Host -Prompt "Enter the name of the JAR deploy storage account"
# Create an Azure storae account and container
New-AzureRmStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $jarStorageAccountName `
    -SkuName "Standard_LRS" `
    -Location $location
$jarStorageAccountKey = (Get-AzureRmStorageAccountKey `
                            -ResourceGroupName $resourceGroupName `
                            -Name $jarStorageAccountName)[0].Value

$jarStorageContext = New-AzureStorageContext `
                            -StorageAccountName $jarStorageAccountName `
                            -StorageAccountKey $jarStorageAccountKey

                            # Get information for the HDInsight cluster
$clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"
# Cluster login is used to secure HTTPS services hosted on the cluster
#$httpCredential = Get-Credential -Message "Enter Cluster login credentials" -UserName "admin"
# SSH user is used to remotely connect to the cluster using SSH clients
#$sshCredentials = Get-Credential -Message "Enter SSH user credentials"

$httpUserName = "admin"
$httpPassword = "1qaz@wsx3edC"
$httpPW = ConvertTo-SecureString -String $httpPassword -AsPlainText -Force
$httpCredential = New-Object System.Management.Automation.PSCredential($httpUserName, $httpPW)

$sshUserName = "sshuser"
$sshPassword = "1qaz@wsx3edC"
$sshPW = ConvertTo-SecureString -String $sshPassword -AsPlainText -Force
$sshCredentials = New-Object System.Management.Automation.PSCredential($sshUserName, $sshPW)

# Default cluster size (# of worker nodes), version, type, and OS
$clusterSizeInNodes = 4
$headNodeSize = "Standard_D13_V2"
$workerNodeSize = "Standard_D14_V2"
$zookeeperNodeSize = "Standard_A1"
$clusterVersion = "3.6"
$clusterType = "INTERACTIVEHIVE" # INTERACTIVEHIVE or SPARK or ...
$clusterOS = "Linux"
$sshPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwTXfsS4+FRigKOYxWt9NYIQ2nSEA+dRu40d2+gkYEaZEuXpTL1VO+PNHzibC9v6zKwBD2bTyvCGb88/ybB6uKicUKlZhNKZs+tSvyrhgF+15Xh/3K1gS+ZAGszt3xUBHPynM4HcOU/anx32zO+lHCRUDPkbSeRlXzUsUJ0tC0aoye9kQsh96jF9Z2OrTPL42eLmLtK+uVNHwQvrhmuYrRAdlTM1we6Brf0AqeX8t1qNTMF9oURNSAFL5S21V+gYQlXIflUSEoFpHEWy/I9Drt6OREW6alxbuTHTw8LFk0E4yIWuOUXgYsnJt84W0EElyip7LJyzEtdg06NSeVhxSB imported-openssh-key" 
# Set the storage container name to the cluster name
$defaultBlobContainerName = $clusterName

# Create a blob container. This holds the default data store for the cluster.
New-AzureStorageContainer `
    -Name $defaultBlobContainerName -Context $defaultStorageContext 

# Create a blob container. This holds the default data store for the cluster.
New-AzureStorageContainer `
    -Name $defaultBlobContainerName -Context $jarStorageContext -Permission Container

$localFileDirectory = "C:\\Users\\shtsukam\\Documents\\git\\hdinsight-deploy\\"

$blobName = "csv-serde-1.1.3-1.2.1.jar"
$localFile = $localFileDirectory + $blobName

Set-AzureStorageBlobContent -File $localFile `
    -Container $defaultBlobContainerName `
    -Blob $blobName `
    -Context $jarStorageContext 

$scriptActionURI = "https://hdiconfigactions.blob.core.windows.net/linuxsetupcustomhivelibsv01/setup-customhivelibs-v01.sh"
$scriptActionParameters = [string]::Join("", "wasbs://", $defaultBlobContainerName, "@", $jarStorageAccountName, ".blob.core.windows.net/") 

$workerScriptActionName = "jardeployToWorker"
$headScriptActionName = "jardeployToHead"

# Create the HDInsight cluster
New-AzureRmHDInsightClusterConfig `
    -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net"  `
    -DefaultStorageAccountKey $defaultStorageAccountKey `
    -ClusterType $clusterType `
    -HeadNodeSize $headNodeSize `
    -WorkerNodeSize $workerNodeSize `
    -ZookeeperNodeSize $zookeeperNodeSize `
            | Add-AzureRmHDInsightStorage `
                -StorageAccountName "$jarStorageAccountName.blob.core.windows.net" `
                -StorageAccountKey $jarStorageAccountKey `
            | Add-AzureRmHDInsightScriptAction `
                -Name $workerScriptActionName `
                -Uri $scriptActionURI `
                -Parameters $scriptActionParameters `
                -NodeType Worker `
            | Add-AzureRmHDInsightScriptAction `
                -Name $headScriptActionName `
                -Uri $scriptActionURI `
                -Parameters $scriptActionParameters `
                -NodeType Head `
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