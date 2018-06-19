$location = @("southeastasia", "japanwest", "japaneast")[2]
$vnetResourceGroupName = "<vnetResourceGroupName>"
$netWorkAddressPrefix = "<netWorkAddressPrefix>"
$hdiotVirtualNetwork = "<hdiotVirtualNetwork>"

# Create the VNresource group
New-AzureRmResourceGroup -Name $vnetResourceGroupName -Location $location

New-AzureRmVirtualNetwork -Name $hdiotVirtualNetwork -ResourceGroupName $vnetResourceGroupName `
    -Location $location -AddressPrefix $netWorkAddressPrefix

