[CmdletBinding()]
Param(

[Parameter(Mandatory=$false)]
$RecoveryVaultName,
[Parameter(Mandatory=$false)]
$RecoveryVaultResourceGroupName,
[Parameter(Mandatory=$false)]
$RecoveryVaultPolicy,
[Parameter(Mandatory=$false)]
$VmResourceGroup,  
[Parameter(Mandatory=$false)]
$VmName
)

If (!([string]::IsNullOrEmpty($RecoveryVaultName)) -and (!([string]::IsNullOrEmpty($RecoveryVaultResourceGroupName)) -and (!([string]::IsNullOrEmpty($RecoveryVaultPolicy)))))
{
    try
    {
        $RecoveryVault = Get-AzRecoveryServicesVault -ResourceGroupName $RecoveryVaultResourceGroupName -Name $RecoveryVaultName
        Set-AzRecoveryServicesVaultContext -Vault $RecoveryVault
      }
    catch
    {
          Write-Error -Message "Unable to Get RecoveryServicesVault. Details: $_" 
    }
    try
    {
        $Policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $RecoveryVaultPolicy
    }
    catch
    {
          Write-Error -Message "Unable to Get RecoveryServicesPolicy. Details: $_" 
    }

    if ((Get-AzRecoveryServicesBackupStatus -Name $VmName -ResourceGroupName $VmResourceGroup -Type AzureVM -ErrorAction SilentlyContinue).BackedUp)
    {
        Write-Output "$VmName is already under backup!"
    }
    else
    {
        Enable-AzRecoveryServicesBackupProtection -Policy $Policy -Name $VmName -ResourceGroupName $VmResourceGroup 
    }

}
else 
{
    Write-Host "There is no RecoveryVault configured"
}






