# Connect to Azure

Connect-AzAccount

$VMdetails = Import-Csv -Path "C:\Users\Naisha\OneDrive\Documents\GitHub\TSS_Code\InputFiles\Build_VM_Inputfile_Single_VM.csv"

$VMdetails | ForEach-Object {

    $resourceGroupName = $_.ResourceGroup
    $location = $_.Location

    # Create the Resource Group if it doesn't exist
    if (-Not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
        Write-Host "Creating Resource Group: $resourceGroupName in $location" -ForegroundColor Green
        $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

        if ($resourceGroup -ne $null) {
            Write-Host "Resource Group $resourceGroupName created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Failed to create Resource Group $resourceGroupName." -ForegroundColor Red
            exit
        }
    }
    else {}

}

# Variables Section
$VMdetails | ForEach-Object -ThrottleLimit 10 -Parallel {
    Start-Sleep -Seconds (Get-Random -Maximum 60)

    $resourceGroupName = $_.ResourceGroup
    $location = $_.Location
    $subnetid = $_.subnet
    $vmname = $_.Name
    $vmSize = $_.Size
    $imagePublisher = $_.publisher
    $imageOffer = $_.Offer
    $imageSku = $_.Sku
    $adminUsername = $_.UserName
    $adminPassword = $_.Password
    
    $VMStatus = Get-AzVM -Name $vmName -EA 0 -WA 0
    if (!$VMStatus) {
        # Create NIC
        $nicName = "$vmname-nic"
        Write-Host "Creating Network Interface $nicName" -fo green
        $nicStatus = Get-AzNetworkInterface -Name $nicName
        if (!$nicStatus) {
            $nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $subnetid -WarningAction 0
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

        New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig -DisableBginfoExtension -wa 0 | Out-null
        Write-Host "VM $vmName created successfully." -fo green
    }   

}
