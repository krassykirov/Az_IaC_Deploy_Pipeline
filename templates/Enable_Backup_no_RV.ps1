[CmdletBinding()]
Param(

[Parameter(Mandatory=$false)]
$RecoveryVaultName,
[Parameter(Mandatory=$false)]
$RecoveryVaultResourceGroupName,
[Parameter(Mandatory=$false)]
$RecoveryVaultPolicy,
[Parameter(Mandatory=$false)]
$ResourceGroupName,
[Parameter(Mandatory=$false)]
$virtualMachineName
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
    
    if ((Get-AzRecoveryServicesBackupStatus -Name $virtualMachineName -ResourceGroupName $ResourceGroupName -Type AzureVM -ErrorAction SilentlyContinue).BackedUp)
    {
        Write-Verbose -message ("$($virtualMachineName) is already under backup") -Verbose
    }
    else
    {
        Write-Verbose -message ("Enabling Backup on $($virtualMachineName)") -Verbose
        Enable-AzRecoveryServicesBackupProtection -Policy $Policy -Name $virtualMachineName -ResourceGroupName $ResourceGroupName -ErrorAction Continue
    }

}
else 
{
    Write-Host "There is no RecoveryVault configured"
}






