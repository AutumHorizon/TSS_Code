# Install-Module -Name Az -AllowClobber -Force
Connect-AzAccount
# Define variables
$resourceGroupName = "kjx-mgt-rg"
$location = "EastUS2"
$storageAccountName = "kjxsqlbackup" + $(Get-Random -Minimum 500 -Maximum 1000) + "sa"
$sku = "Standard_LRS"
$kind = "StorageV2"

# Create the Resource Group
Write-Host "Creating Resource Group: $resourceGroupName in $location" -ForegroundColor Green
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

if ($resourceGroup -ne $null) {
    Write-Host "Resource Group $resourceGroupName created successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to create Resource Group $resourceGroupName." -ForegroundColor Red
    exit
}

    # Create the Storage Account
    Write-Host "Creating Storage Account: $storageAccountName in $resourceGroupName" -ForegroundColor Green
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -SkuName $sku -Kind $kind -Location $location -wa 0
    
    if ($storageAccount -ne $null) {
        Write-Host "Storage Account $storageAccountName created successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to create Storage Account $storageAccountName." -ForegroundColor Red
    }

# Output storage account details
$storageAccountDetails = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
Write-Host "Storage Account Details:" -ForegroundColor Yellow
Write-Host "Name: $($storageAccountDetails.StorageAccountName)" -ForegroundColor Yellow
Write-Host "Resource Group: $($storageAccountDetails.ResourceGroupName)" -ForegroundColor Yellow
Write-Host "Location: $($storageAccountDetails.PrimaryLocation)" -ForegroundColor Yellow
Write-Host "SKU: $($storageAccountDetails.Sku.Name)" -ForegroundColor Yellow
Write-Host "Kind: $($storageAccountDetails.Kind)" -ForegroundColor Yellow

