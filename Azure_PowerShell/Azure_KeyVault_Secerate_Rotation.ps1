param (
    [string]$KeyVaultName,
    [string]$SecretName
)

# Authenticate with Managed Identity
Connect-AzAccount -Identity

# Generate a New Secret Value
$NewSecretValue = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % {[char]$_})

# Update the Secret in Key Vault
$Secret = ConvertTo-SecureString -String $NewSecretValue -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $Secret

# Output the new secret version
Write-Output "Secret '$SecretName' has been updated successfully in Key Vault: $KeyVaultName"