Connect-AzAccount

# Define variables
$resourceGroupName = "kjx-net-rg"
$location = "EastUS2"
$vnetName = "kjx-0-vnet"
$addressPrefix = "10.0.0.0/16"
$subnetName = "kjx-0-mgt-snet"
$subnetPrefix = "10.0.1.0/24"

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

# Create the Virtual Network
Write-Host "Creating Virtual Network: $vnetName in Resource Group: $resourceGroupName" -ForegroundColor Green
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix $addressPrefix

if ($vnet -ne $null) {
    Write-Host "Virtual Network $vnetName created successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to create Virtual Network $vnetName." -ForegroundColor Red
    exit
}

# Create the Subnet
Write-Host "Creating Subnet: $subnetName in Virtual Network: $vnetName" -ForegroundColor Green
$subnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $subnetPrefix

# Update the Virtual Network with the Subnet configuration
$sc = Set-AzVirtualNetwork -VirtualNetwork $vnet

if ($subnet -ne $null) {
    Write-Host "Subnet $subnetName created successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to create Subnet $subnetName." -ForegroundColor Red
    exit
}

# Output VNet details
$vnetDetails = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName
Write-Host "Virtual Network Details:" -ForegroundColor Yellow
Write-Host "Name: $($vnetDetails.Name)" -ForegroundColor Yellow
Write-Host "Resource Group: $($vnetDetails.ResourceGroupName)" -ForegroundColor Yellow
Write-Host "Location: $($vnetDetails.Location)" -ForegroundColor Yellow
Write-Host "Address Prefix: $($vnetDetails.AddressSpace.AddressPrefixes)" -ForegroundColor Yellow

# Output Subnet details
$subnetDetails = $vnetDetails.Subnets | Where-Object { $_.Name -eq $subnetName }
Write-Host "Subnet Details:" -ForegroundColor Yellow
Write-Host "Name: $($subnetDetails.Name)" -ForegroundColor Yellow
Write-Host "Address Prefix: $($subnetDetails.AddressPrefix)" -ForegroundColor Yellow
