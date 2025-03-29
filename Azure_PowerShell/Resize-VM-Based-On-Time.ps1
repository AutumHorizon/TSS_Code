param (
    [string]$ResourceGroupName = "YourResourceGroup",
    [string]$VMName = "YourVM",
    [string]$Mode = "ScaleDown", # Accepts "ScaleUp" or "ScaleDown"
    [string]$LowerSKU = "Standard_B2s", # Lower SKU for off-hours
    [string]$HigherSKU = "Standard_D2ds_v5" # Higher SKU for business hours
)

# Connect to Azure using Managed Identity
Connect-AzAccount -Identity

# Get the current VM state
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
$currentSize = $vm.HardwareProfile.VmSize

# Determine target size
if ($Mode -eq "ScaleDown") {
    $TargetSKU = $LowerSKU
} elseif ($Mode -eq "ScaleUp") {
    $TargetSKU = $HigherSKU
} else {
    Write-Output "Invalid Mode. Use 'ScaleUp' or 'ScaleDown'."
    exit 1
}

# Check if resizing is needed
if ($currentSize -eq $TargetSKU) {
    Write-Output "VM is already on $TargetSKU. No resizing needed."
    exit 0
}

# Deallocate VM before resizing
Write-Output "Deallocating VM $VMName..."
Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force -NoWait | Out-null

# Wait until the VM is fully deallocated
$vmStatus = ""
while ($vmStatus -ne "VM deallocated") {
    Start-Sleep -Seconds 10
    $vmStatus = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status).Statuses[1].DisplayStatus
    Write-Output "Current VM Status: $vmStatus"
}

Write-Output "VM successfully deallocated. Proceeding with resizing."

# Resize VM
Write-Output "Resizing VM $VMName to $TargetSKU..."
$vm.HardwareProfile.VmSize = $TargetSKU
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm | Out-Null

# Start VM after resizing
Write-Output "Starting VM $VMName..."
Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName | Out-Null

Write-Output "VM $VMName resized to $TargetSKU successfully."
