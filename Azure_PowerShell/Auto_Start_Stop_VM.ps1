param(
    [string] $ResourceGroupName,
    [string] $NameSubstring,
    [ValidateSet("Start", "Stop")]
    [string] $Action
)


try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Retrieve and filter VMs
try {
    Write-Output "Fetching VMs in Resource Group '$ResourceGroupName' containing '$NameSubstring'..."
    $filteredVMs = Get-AzVM -ResourceGroupName $ResourceGroupName | Where-Object {
        $_.Name -like "*$NameSubstring*"
    } | Select-Object -ExpandProperty Name

    if ($filteredVMs.Count -eq 0) {
        Write-Error "No VMs found with names containing '$NameSubstring'."
        exit
    }

    Write-Output "Found VMs: $($filteredVMs -join ', ')"
}
catch {
    Write-Error "Error retrieving VMs: $_"
    exit
}

# Perform the specified action on each filtered VM
foreach ($VM in $filteredVMs) {
    try {
        if ($Action -eq "Start") {
            Write-Output "Starting VM '$VM' in Resource Group '$ResourceGroupName'..."
            Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VM -NoWait
            Write-Output "Start command issued for VM '$VM'."
        }
        elseif ($Action -eq "Stop") {
            Write-Output "Stopping VM '$VM' in Resource Group '$ResourceGroupName'..."
            Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VM -Force -NoWait
            Write-Output "Stop command issued for VM '$VM'."
        }
    }
    catch {
        Write-Error "Error processing VM '$VM': $_"
    }
}