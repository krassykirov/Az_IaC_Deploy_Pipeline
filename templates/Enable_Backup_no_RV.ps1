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
[string[]]$VMS
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
    
     foreach ($VirtualMachineName in $VMS)
        {
            $VM = Get-AzVM -name $VirtualMachineName

            if ($VM -eq $null)
            {
                Write-Verbose -message ("$VirtualMachineName does not exist!") -Verbose
                Continue 
            }
            elseif ((Get-AzRecoveryServicesBackupStatus -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Type AzureVM -ErrorAction SilentlyContinue).BackedUp)
            {
              Write-Verbose -message ("$($VM.Name) is already under backup") -Verbose
              Continue
            }
            else
            { 
               Write-Verbose -message ("Enable Backup on $($VM.Name)") -Verbose
               Enable-AzRecoveryServicesBackupProtection -Policy $Policy -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -ErrorAction Continue
            }
        }

}
else 
{
    Write-Host "There is no RecoveryVault configured"
}






