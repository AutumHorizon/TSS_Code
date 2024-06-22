Connect-AzAccount

# Define variables

$resourceGroupName = "kjx-0-mgt-rg"
$location = "EastUS2"
$vnetName = "kjx-0-vnet"
$subnetName = "kjx-0-mgt-snet"
$nsgName = "kjx-0-mgt-nsg"
$vmName = "kjx0mgtdc001vm"
$publicIpName = "$vmName-pip"
$vmSize = "Standard_B2ms"
$imagePublisher = "MicrosoftWindowsServer"
$imageOffer = "WindowsServer"
$imageSku = "2019-Datacenter"
$adminUsername = "azureuser"
$adminPassword = "P@ssw0rd!"


# Create the Resource Group if it doesn't exist
if (-Not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating Resource Group: $resourceGroupName in $location" -ForegroundColor Green
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

    if ($resourceGroup -ne $null) {
        Write-Host "Resource Group $resourceGroupName created successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to create Resource Group $resourceGroupName." -ForegroundColor Red
        exit
    }
} else {
    Write-Host "Resource Group $resourceGroupName already exists." -ForegroundColor Yellow
}

# Create the Network Security Group
Write-Host "Creating Network Security Group: $nsgName in Resource Group: $resourceGroupName" -ForegroundColor Green
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName

# Create the Public IP Address
Write-Host "Creating Public IP Address: $publicIpName in Resource Group: $resourceGroupName" -ForegroundColor Green
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -Name $publicIpName -AllocationMethod Static

# Get the existing Virtual Network and Subnet
$vnet = Get-AzVirtualNetwork -Name $vnetName
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

$VMStatus = Get-AzVM -Name $vmName -EA 0 -WA 0
if (!$VMStatus) {
    # Create NIC
    $nicName = "$vmName-nic"
    Write-Host "Creating Network Interface $nicName" -fo green
    $nicStatus = Get-AzNetworkInterface -Name $nicName
    if (!$nicStatus) {
        $nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $subnet.id -PublicIpAddressId $publicIp.Id
    }
    else {
        $nic = $nicStatus
    }

    Write-Host "Creating VM $vmName" -fo green
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $($vmSize)
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential (New-Object PSCredential ($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force)))
    $vmConfig = Set-AzVMOSDisk -VM $Vmconfig -Name "$VmName-OSDisk" -Windows -CreateOption FromImage -DeleteOption Delete -StorageAccountType Standard_LRS
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
    $vmConfig = Set-AzVMBootDiagnostic -vm $vmConfig -Enable
    $vmConfig = Set-AzVMSourceImage -VM $Vmconfig -PublisherName $imagePublisher -Skus $imagesku -Offer $imageoffer -Version "latest"

    New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig -DisableBginfoExtension | Out-null
    Write-Host "VM $vmName created successfully." -fo green
}  

# Verify VM creation
$vm = Get-AzVM -Name $vmName -Status
if ($vm.PowerState -eq 'VM running') {
    Write-Host "Virtual Machine $vmName created successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to create Virtual Machine $vmName." -ForegroundColor Red
}
