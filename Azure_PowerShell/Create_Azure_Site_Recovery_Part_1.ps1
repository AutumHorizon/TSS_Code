[CmdletBinding()]
param (
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]$Subscription,
  
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]$CustomerCode,
  
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]$PRvNET,
  
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]$DRvNET,
  
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]$PRLocation,
  
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]$DRLocation
)

#================================================#
# Set Variables
#------------------------------------------------#

$CustomerCode = $CustomerCode.ToLower()
$PRLocation = $PRLocation.ToLower()
$DRLocation = $DRLocation.ToLower()

$RSVResGroup = $CustomerCode + '-1-disasterrecovery-rg'
$RSVName = $CustomerCode + '-1-disasterecovery-rsv'

$PRASRFabric = $CustomerCode + '-' + $PRLocation
$DRASRFabric = $CustomerCode + '-' + $DRLocation

$PRProtectContainer = $CustomerCode + 'prprotectioncontainer'
$DRProtectContainer = $CustomerCode + 'drprotectioncontainer'

$ASRPRCacheSAName = $CustomerCode + '1prasrcache'
$ASRPRCacheSAResGroup = $CustomerCode + '-1-disasterrecovery-rg'

$ASRPRTargetSAName = $CustomerCode + '1prasrtarget'
$ASRPRTargetSAResGroup = $CustomerCode + '-1-disasterrecovery-rg'

$PRtoDRNetworkMapping = $CustomerCode + 'pr2drnetworkmapping'
$DRtoPRNetworkMapping = $CustomerCode + 'dr2prnetworkmapping'
#------------------------------------------------#

#================================================#
# Session Initialization                         #
#------------------------------------------------#
Write-Output ""

### Check for Azure Connection
$AzureStatus = Get-AzContext -EA 0 -WA 0
If ( !$AzureStatus ) {
  $CA = Connect-AzAccount
  $AzureStatus = Get-AzContext -EA 0 -WA 0
}
If ( !$AzureStatus ) {
  Write-Output "ALERT: Not Connected to Azure!"
  Write-Output ""
  Write-Output "Processing Stopped!"
  Write-Output ""
  Exit
}

### Set Azure Context as needed
$CurrentContext = $AzureStatus.Subscription.Name
If ( $CurrentContext -notmatch $Subscription ) {
  $AC = Set-AzContext -Subscription $Subscription -EA 0 -WA 0
  Write-Output "Context Set to '$Subscription'"
  Write-Output ""
}
#------------------------------------------------#

#================================================#
# Create Recovery Services Vault                 #
#------------------------------------------------#
Write-Output "Creating Recovery Services Vault..."
Write-Output ""

### Create Resource Group for Recovery Services Vault in the Recovery Azure Region
## $RSVResGroup = 'xyz-1-disasterrecovery-rg'
$RGStatus = Get-AzResourceGroup -Location $DRLocation -Name $RSVResGroup -EA 0 -WA 0
If ( !$RGStatus ) {
  $RG = New-AzResourceGroup -Name $RSVResGroup -Location $DRLocation
}

### Create Recovery Services Vault in the Recovery Region
## $RSVName = 'xyz-1-disasterecovery-rsv'
$RSV = New-AzRecoveryServicesVault -Location $DRLocation -ResourceGroupName $RSVResGroup -Name $RSVName

### Set RSV Context
$SC = Set-AzRecoveryServicesAsrVaultContext -Vault $RSV
#------------------------------------------------#

#================================================#
# Create ASR Fabrics                             #
#------------------------------------------------#
Write-Output "Creating ASR Fabrics..."
Write-Output ""

### Create Primary ASR Fabric
#-- Create Fabric
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location $PRLocation -Name $PRASRFabric
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#-- Get Fabric
## $PRASRFabric = 'xyz-eastus2'
$PRFabric = Get-AzRecoveryServicesAsrFabric -Name $PRASRFabric

### Create DR ASR Fabric
#-- Create Fabric
## $PRASRFabric = 'xyz-centralus'
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location $DRLocation -Name $DRASRFabric
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#-- Get Fabric
$DRFabric = Get-AzRecoveryServicesAsrFabric -Name $DRASRFabric
#------------------------------------------------#

#================================================#
# Create Protection Containers                   #
#------------------------------------------------#
Write-Output "Creating Protection Containers..."
Write-Output ""

### Create a Protection Container in the Primary Azure Region (within the Primary Fabric)
#-- Create Container
## $PRProtectContainer = xyzprprotectioncontainer'
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PRFabric -Name $PRProtectContainer
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#-- Get Container
$PRProtectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PRFabric -Name $PRProtectContainer

### Create a Protection Container in the Recovery Azure Region (within the DR Fabric)
#-- Create Container
## $DRProtectContainer = xyzdrprotectioncontainer'
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $DRFabric -Name $DRProtectContainer
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#-- Get Container
$DRProtectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $DRFabric -Name $DRProtectContainer
#------------------------------------------------#

#================================================#
# Create Replication Policy                      #
#------------------------------------------------#
Write-Output "Creating Replication Policy..."
Write-Output ""

#-- Create Policy
$TempASRJob = New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name "24-hour-rentention-policy" -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#-- Get Policy
$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name "24-hour-rentention-policy"
#------------------------------------------------#

#================================================#
# Create Protection Container Mapping            #
#------------------------------------------------#
Write-Output "Creating Protection Container Mapping..."
Write-Output ""

### Create Protection Container Mapping between the Primary and Recovery Protection Containers with the Replication Policy
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "A2APrimaryToRecovery" `
-Policy $ReplicationPolicy `
-PrimaryProtectionContainer $PRProtectionContainer `
-RecoveryProtectionContainer $DRProtectionContainer
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#-- Get Protection Container Mapping
$PRtoDRMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PRProtectionContainer -Name "A2APrimaryToRecovery"

### Create Protection Container Mapping (for fail back) between the Recovery and Primary Protection Containers with the Replication Policy
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "A2ARecoveryToPrimary" `
-Policy $ReplicationPolicy `
-PrimaryProtectionContainer $DRProtectionContainer `
-RecoveryProtectionContainer $PRProtectionContainer
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#-- Get Protection Container Mapping
$DRtoPRMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $DRProtectionContainer -Name "A2ARecoveryToPrimary"
#------------------------------------------------#

#================================================#
# Create Storage Accounts                        #
#------------------------------------------------#
Write-Output "Creating Storage Accounts..."
Write-Output ""

### Create Cache Storage Account for Replication Logs in the Primary Region
## $ASRPRCacheSAName = 'xyz1prasrcache'

$CacheStorageAccount = New-AzStorageAccount `
  -Location $PRLocation `
  -ResourceGroupName $ASRPRCacheSAResGroup `
  -Name $ASRPRCacheSAName `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -AllowBlobPublicAccess $False `
  -EnableHttpsTrafficOnly $True `
  -MinimumTlsVersion TLS1_2

### Create Target Storage Account in the Recovery Region. In this case a Standard Storage Account
## $ASRPRTargetSAName = 'xyz1prasrtarget' 
$TargetStorageAccount = New-AzStorageAccount `
  -Location $DRLocation `
  -ResourceGroupName $ASRPRTargetSAResGroup `
  -Name $ASRPRTargetSAName `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -AllowBlobPublicAccess $False `
  -EnableHttpsTrafficOnly $True `
  -MinimumTlsVersion TLS1_2

#------------------------------------------------#

#================================================#
# Create Network Mappings                        #
#------------------------------------------------#
Write-Output "Creating Network Mappings..."
Write-Output ""

### Get vNET IDs
$PRVnetID = (Get-AzVirtualNetwork -Name $PRvNET).Id
$DRVnetID = (Get-AzVirtualNetwork -Name $DRvNET).Id

### Create Network Mapping between the Primary vNET and DR vNET

## $PRtoDRNetworkMapping = 'xyzpr2drnetworkmapping'

$TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure `
-Name $PRtoDRNetworkMapping -PrimaryFabric `
$PRFabric -PrimaryAzureNetworkId $PRVnetID `
-RecoveryFabric $DRFabric `
-RecoveryAzureNetworkId $DRVnetID
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}

### Create Network Mapping between the DR vNET and Primary vNET
## $DRtoPRNetworkMapping = 'xyzdr2prnetworkmapping'

$TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name $DRtoPRNetworkMapping `
-PrimaryFabric $DRFabric `
-PrimaryAzureNetworkId $DRVnetID `
-RecoveryFabric $PRFabric `
-RecoveryAzureNetworkId $PRVnetID
#-- Wait for Job to complete
While ( $TempASRJob.State -eq 'InProgress' -or $TempASRJob.State -eq 'NotStarted' ) {
  Start-Sleep 10
  $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#-- Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
If ( $TempASRJob.State -ne 'Succeeded' ) {
  Write-Output "ALERT: Job Failed - $($TempASRJob.State)"
}
#------------------------------------------------#

#================================================#
# Replicate Azure VMs                            #
#------------------------------------------------#

Write-Output "Replicating VMs..."
Write-Output ""

### Get List of VMs to process
$VMList = Get-AzVM -Status | Sort-Object Name
### Get List of VMs Already Protected
$ProtectedVMs = @((Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PRProtectionContainer).RecoveryAzureVMName)

Foreach ( $VM in $VMList ) {
  $VMName = $VM.Name
  Write-Output "  Processing $VMName"
  
  #-- Process VM if not already Protected
  If ( $ProtectedVMs -contains $VMName ) {
    Write-Output "    Already Replicated"
  } `
    ElseIf ( $VM.PowerState -notmatch 'running' ) {
    Write-Output "    Cannot Replicate; VM is not running"
  } `
    Else {
    Write-Output "    Creating Replication"
    
    #-- Get VM Object
    $VMObject = Get-AzVM -Name $VMName
    
    #-- Set Variables
    $PRResGroupName = $VMObject.ResourceGroupName.ToLower()
    $DRResGroupName = $PRResGroupName + '-asr'
    
    #-- Get DR Resource Group; Create if needed
    $DRResGroup = Get-AzResourceGroup -Name $DRResGroupName -Location $DRLocation -EA 0 -WA 0
    If ( !$DRResGroup ) { $DRResGroup = New-AzResourceGroup -Name $DRResGroupName -Location $DRLocation }
    
    $VMZone = ''
    If ( $VMObject.Zones ) { $VMZone = [string]$VMObject.Zones }
    
    #-- Specify Replication Properties for each disk of the VM that is to be replicated (Create Disk Replication Configuration)
    $DiskConfigs = @()
    #-- OS Disk
    $OSDiskId = $VMObject.StorageProfile.OsDisk.ManagedDisk.Id
    $RecoveryReplicaDiskAccountType = $VMObject.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
    
    $OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig `
      -ManagedDisk `
      -LogStorageAccountId $CacheStorageAccount.Id `
      -DiskId $OSDiskId `
      -RecoveryResourceGroupId $DRResGroup.ResourceId `
      -RecoveryReplicaDiskAccountType $RecoveryReplicaDiskAccountType `
      -RecoveryTargetDiskAccountType $RecoveryReplicaDiskAccountType
    
    $DiskConfigs += $OSDiskReplicationConfig
    
    If ( $VMObject.StorageProfile.DataDisks ) {
      Foreach ( $Disk in $VMObject.StorageProfile.DataDisks ) {
        if ($disk.Name -notmatch "NonReplication_Data_disk") {
          $DataDiskId = $Disk.ManagedDisk.Id
          $RecoveryReplicaDiskAccountType = $Disk.ManagedDisk.StorageAccountType
        
          $DataDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig `
            -ManagedDisk `
            -LogStorageAccountId $CacheStorageAccount.Id `
            -DiskId $DataDiskId `
            -RecoveryResourceGroupId $DRResGroup.ResourceId `
            -RecoveryReplicaDiskAccountType $RecoveryReplicaDiskAccountType `
            -RecoveryTargetDiskAccountType $RecoveryReplicaDiskAccountType
          $DiskConfigs += $DataDiskReplicationConfig
        }
      }
    }
    
    #-- Start replication by creating replication protected item. Using a GUID for the name of the replication protected item to ensure uniqueness of name.
    If ( $VMZone ) {
      $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem `
        -AzureToAzure `
        -AzureVmId $VMObject.Id `
        -Name (New-Guid).Guid `
        -ProtectionContainerMapping $PRtoDRMapping `
        -RecoveryResourceGroupId $DRResGroup.ResourceId `
        -RecoveryAvailabilityZone $VMZone `
        -AzureToAzureDiskReplicationConfiguration $DiskConfigs
    } `
      Else {
      $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem `
        -AzureToAzure `
        -AzureVmId $VMObject.Id `
        -Name (New-Guid).Guid `
        -ProtectionContainerMapping $PRtoDRMapping `
        -RecoveryResourceGroupId $DRResGroup.ResourceId `
        -AzureToAzureDiskReplicationConfiguration $DiskConfigs
    }
  }
}
#------------------------------------------------#

Write-Output ""
Write-Output "Processing Complete."
Write-Output ""
#=======================================================================#
