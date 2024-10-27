# Define the file path where the input CSV file is located.
# The CSV file should contain the details of VMs to resize, including SubscriptionName, ResourceGroupName, VMName, and NewVMSize.
$csvFilePath = "C:\Users\Naisha\OneDrive\Documents\GitHub\TSS_Code\InputFiles\Resize_VM_Inputfile.csv"

# Import the CSV file into a variable.
# Import-Csv reads the contents of the CSV file and converts each row into an object with properties corresponding to the column headers.
# Each row in the CSV represents one VM that needs to be resized.
$vmsToResize = Import-Csv -Path $csvFilePath

# Loop through each VM entry in the CSV file.
# 'foreach' iterates over each object (row) in the $vmsToResize array.
# Each $vm object represents one row in the CSV, with properties like SubscriptionName, ResourceGroupName, VMName, and NewVMSize.
foreach ($vm in $vmsToResize) {
    # Extract subscription name, resource group name, VM name, and the new VM size from the current CSV row.
    # These variables hold information for the specific VM that is being processed in this iteration.
    $subscriptionName = $vm.SubscriptionName    # The subscription under which the VM exists.
    $resourceGroupName = $vm.ResourceGroupName  # The resource group that contains the VM.
    $vmName = $vm.VMName                        # The name of the VM to be resized.
    $newVMSize = $vm.NewVMSize                  # The target size to which the VM will be resized.

    # Inform the user about the VM being processed.
    # Write-Host is used to display messages in the PowerShell console.
    Write-Host "Processing VM '$vmName' in Subscription '$subscriptionName', Resource Group '$resourceGroupName'..." -ForegroundColor Cyan

    try {
        # Retrieve the current Azure subscription context.
        # This helps us determine if we need to switch to a different subscription before making changes to the VM.
        # Get-AzContext retrieves the current context, including subscription details.
        $currentSubscription = (Get-AzContext).Subscription.Name

        # Compare the current subscription with the one required for the current VM.
        # If they are different, switch to the subscription specified in the CSV.
        if ($currentSubscription -ne $subscriptionName) {
            # Notify the user that the script is switching to a different subscription.
            Write-Host "Switching to subscription '$subscriptionName'..." -ForegroundColor Yellow
            # Select-AzSubscription changes the active Azure subscription context to the specified subscription.
            # This ensures that subsequent commands are executed under the correct subscription.
            Select-AzSubscription -SubscriptionName $subscriptionName | out-null
            Write-Host "Switched to subscription '$subscriptionName'." -ForegroundColor Green
        } else {
            # If the current subscription is already the desired one, inform the user that no switch is needed.
            Write-Host "Already in the subscription '$subscriptionName'. No switch needed." -ForegroundColor Green
        }

        # Stop the virtual machine before resizing it.
        # Stopping the VM ensures that changes to its size can be made without conflicts.
        Write-Host "Stopping VM '$vmName'..." -ForegroundColor Yellow
        # Stop-AzVM stops the specified virtual machine.
        # -Force bypasses any confirmation prompts, and -NoWait allows the script to proceed without waiting for the stop operation to complete.
        Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Force -NoWait | out-null

        # Notify the user that the script is waiting for the VM to stop completely.
        Write-Host "Waiting for VM '$vmName' to stop..."

        # Initialize a flag variable to track the deallocation status of the VM.
        $vmStopped = $false

        # Use a loop to check if the VM has fully stopped.
        # The VM must reach the 'deallocated' state before resizing can proceed.
        while (-not $vmStopped) {
            # Retrieve the current status of the VM to check if it is deallocated.
            # Get-AzVM -Status provides the VM's status, including power state.
            # The Where-Object filters the statuses to find the 'deallocated' state.
            $vmStatus = (Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status).Statuses |
                Where-Object { $_.Code -eq 'PowerState/deallocated' }

            # If the 'deallocated' status is found, set $vmStopped to $true to exit the loop.
            if ($vmStatus) {
                $vmStopped = $true
            } else {
                # If the VM is not yet deallocated, wait for 10 seconds before checking again.
                # Start-Sleep pauses the script for the specified time.
                Start-Sleep -Seconds 10
                # Inform the user that the script is still waiting for the VM to stop.
                Write-Host "VM '$vmName' is still stopping. Waiting..." -ForegroundColor Yellow
            }
        }

        # Inform the user that the VM has successfully stopped.
        Write-Host "VM '$vmName' stopped successfully." -ForegroundColor Green

        # Retrieve the current VM object, which includes the VM's configuration.
        # Get-AzVM fetches the VM details, including its hardware profile that contains the current size.
        $virtualMachine = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

        # Modify the VM's hardware profile to the new size specified in the CSV.
        # The HardwareProfile property allows us to change the VM size before updating it.
        $virtualMachine.HardwareProfile.VmSize = $newVMSize

        # Apply the updated VM size to the Azure VM configuration.
        # Update-AzVM pushes the new configuration (including the size change) to the Azure VM.
        Write-Host "Updating VM size to '$newVMSize'..." -ForegroundColor Yellow
        Update-AzVM -ResourceGroupName $resourceGroupName -VM $virtualMachine | Out-Null
        # Notify the user that the VM resizing operation was successful.
        Write-Host "VM '$vmName' resized successfully to '$newVMSize'." -ForegroundColor Green

        # Start the VM after resizing it to bring it back online.
        # This ensures the VM is running with its new configuration.
        Write-Host "Starting VM '$vmName'..." -ForegroundColor Yellow
        Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName | out-null
        # Inform the user that the VM has been started.
        Write-Host "VM '$vmName' started successfully." -ForegroundColor Green
    }
    catch {
        # If an error occurs during any of the above steps, catch the exception and display an error message.
        # $_ contains the error message from the exception, providing details on what went wrong.
        Write-Host "Failed to process VM '$vmName'. Error: $_" -ForegroundColor Red
    }
}

# Inform the user that the resizing process is complete for all VMs listed in the CSV.
Write-Host "VM resizing process completed for all entries."
