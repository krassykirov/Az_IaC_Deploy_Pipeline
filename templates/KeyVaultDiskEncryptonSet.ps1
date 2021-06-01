[CmdletBinding()]
Param(

$Prefix = $SubscriptionName,
$ResourceGroupName, # ='VMs',
$ENV, # = "Dev",
$Location, # = 'west europe',
$SPNID # = '6b00e15f-ac07-4f91-9ffe-0442e6fac969'
  
)

$keyVaultName = 'KR-'+ $ENV +"-KV-$Prefix"
$DiskEncryptionSetName = 'DE-'+ $ENV + "-DES-"+ "$Prefix"
$keyName = 'KeY'+ $ENV + "IaaS-key02" 
If(!(Get-AzResource -Name $keyVaultName -ErrorAction SilentlyContinue))
{   
    Write-Output "Creating Key Vault, Encryption Key and Disk Encryption Set"
    $keyVault = New-AzKeyVault -Name $keyVaultName -ResourceGroupName $ResourceGroupName -Location $Location -EnabledForDiskEncryption -EnabledForTemplateDeployment -EnablePurgeProtection -SoftDeleteRetentionInDays 7
    Set-AzKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $SPNID -PermissionsToKeys wrapkey,unwrapkey,get,create, delete, list, update, import -BypassObjectIdValidation
    $key = Add-AzKeyVaultKey -VaultName $keyVault.VaultName -Name $keyName -Destination Software 

    $Deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
        -TemplateUri "https://raw.githubusercontent.com/Azure-Samples/managed-disks-powershell-getting-started/master/AutoKeyRotation/CreateDiskEncryptionSetWithAutoKeyRotation.json" `
        -diskEncryptionSetName $DiskEncryptionSetName `
        -keyVaultId $keyVault.ResourceId `
        -keyVaultKeyUrl $key.Id `
        -encryptionType "EncryptionAtRestWithCustomerKey" `
        -region WestEurope 

    sleep 5
    $DiskEncryptionSet = Get-AzDiskEncryptionSet -Name $DiskEncryptionSetName 
    Set-AzKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $DiskEncryptionSet.Identity.PrincipalId -PermissionsToKeys wrapkey,unwrapkey,get -BypassObjectIdValidation
   
    $DiskEncryptionSetId = $DiskEncryptionSet.Id
    $DiskEncryptionSet = $DiskEncryptionSet.Name
    Write-Output "DiskEncryptionSet: $DiskEncryptionSet"
    Write-Verbose -message "DiskEncryptionSet and Key Vault has been created"
    Write-Output "DiskEncryptionSetID: $($DiskEncryptionSet.Id)"
    Write-Host "Setting up Variables DiskEncryptionSet & DiskEncryptionSetId"
    Write-Host "##vso[task.setvariable variable=DiskEncryptionSetId;isOutput=true;]$DiskEncryptionSetId"
    Write-Host "##vso[task.setvariable variable=DiskEncryptionSet;isOutput=true;]$DiskEncryptionSet"
  }    

else 
{
    Write-Output "Key Vault $keyVaultName exist" 
    Write-Output "DiskEncryptionSet: $DiskEncryptionSet exist"
    Write-Verbose -message "DiskEncryptionSet and Key Vault already exist"
    $keyVault = Get-AzKeyVault -VaultName $keyVaultName
    $diskEncryptionSetId = (Get-AzDiskEncryptionSet -Name $diskEncryptionSetName -ResourceGroupName $ResourceGroupName).Id

    Write-Output "DiskEncryptionSetID is: $diskEncryptionSetId"
    Write-Host "##vso[task.setvariable variable=diskEncryptionSetId;isOutput=true;]$diskEncryptionSetId"
    Write-Host "##vso[task.setvariable variable=DiskEncryptionSet;isOutput=true;]$DiskEncryptionSet"
}
 

