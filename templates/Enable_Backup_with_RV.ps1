[CmdletBinding()]
Param(

[Parameter(Mandatory=$false)]
$RecoveryVaultName,
[Parameter(Mandatory=$false)]
$RecoveryVaultResourceGroupName,
[Parameter(Mandatory=$false)]
$RecoveryVaultPolicy,
[Parameter(Mandatory=$false)]
$subscriptionId,  
[Parameter(Mandatory=$false)]
[string[]]$VMS
)

try
{
  Set-AzContext -SubscriptionId $subscriptionId
}
catch
{
  Write-Error -Message "Unable to Get Azure Subscription. Details: $_" -ErrorAction Stop
}

If (!([string]::IsNullOrEmpty($RecoveryVaultName)) -and (!([string]::IsNullOrEmpty($RecoveryVaultResourceGroupName)) -and (!([string]::IsNullOrEmpty($RecoveryVaultPolicy)))))
{

    if ((Get-AzRecoveryServicesVault -Name $RecoveryVaultName) -eq $null) 
    {
        Write-Output "RecoveryVault: $RecoveryVaultName does not exist"
        Write-Output "Creating $RecoveryVaultName.."
        # Creating a new RecoveryVault, Default Backup configuration for Storage Replication Type is set to Geo-redundant (GRS). Default Security settings for Soft Delete is enabled. 
        try
        {
            $RecoveryVault = New-AzRecoveryServicesVault -Name $RecoveryVaultName -ResourceGroupName $RecoveryVaultResourceGroupName -Location "West Europe"
            $null = Get-AzRecoveryServicesVault -Name $RecoveryVault.Name | Set-AzRecoveryServicesVaultContext
        }
        catch
        {
            Write-Error "Unable to Create Recovery Services Vault.Details:$_" -ErrorAction Stop
        }
        # Get-AzRecoveryServicesBackupSchedulePolicyObject to obtain and setup the default schedule policy
        try
        {
            $SchPol = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM" 
            $SchPol.ScheduleRunTimes.Clear()
            $Date = Get-Date -Date "2021-06-01 08:00:00Z"
            $SchPol.ScheduleRunTimes.Add($Date.ToUniversalTime())
            $SchPol.ScheduleRunFrequency = "Daily"
        }
        catch
        {
            Write-Error "Unable to Setup Backup Schedule Policy Object.Details:$_" -ErrorAction Stop
        }
        # Get-AzRecoveryServicesBackupRetentionPolicyObject to view and setup the default retention policy.
        try
        {
            $RetPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM" 
            $RetPol.DailySchedule.DurationCountInDays = 30
            $RetPol.IsWeeklyScheduleEnabled  = $false
            $RetPol.IsMonthlyScheduleEnabled = $false
            $RetPol.IsYearlyScheduleEnabled  = $false
        }
        catch
        {
            Write-Error "Unable to Setup Backup Retention Policy Object Details:$_" -ErrorAction Stop
        }
        try
        {
        # Creating new Policy
            New-AzRecoveryServicesBackupProtectionPolicy -Name $RecoveryVaultPolicy -WorkloadType AzureVM -RetentionPolicy $RetPol -SchedulePolicy $SchPol
        }
        catch
        {
            Write-Error "Unable to Create Backup Protection Policy Details:$_" -ErrorAction Stop
        }
    }

    elseif ((Get-AzRecoveryServicesVault -Name $RecoveryVaultName) -ne $null) 
    {
        try
        {
            # Getting RecoveryVault and set the RecoveryVault Context
            $RecoveryVault = Get-AzRecoveryServicesVault -ResourceGroupName $RecoveryVaultResourceGroupName -Name $RecoveryVaultName
            Set-AzRecoveryServicesVaultContext -Vault $RecoveryVault
        }
        catch
        {
            Write-Error -Message "Unable to Get RecoveryServicesVault. Details: $_" -ErrorAction Stop
        }
        try
        {
            $Policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $RecoveryVaultPolicy
        }
        catch
        {
            Write-Error -Message "Unable to Get RecoveryServicesPolicy. Details: $_" -ErrorAction Stop
        }

        foreach ($VirtualMachine in $VMS)
        {
            $VM = Get-AzVM -name $VirtualMachine

            if ($VM -eq $null)
            {
                Write-Output "$($VirtualMachine) does not exist!" 
                Continue 
            }
            elseif ((Get-AzRecoveryServicesBackupStatus -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Type AzureVM -ErrorAction SilentlyContinue).BackedUp)
            {
              Write-Output "$($VM.Name) is already under backup." 
              Continue
            }
            else
            {
                Enable-AzRecoveryServicesBackupProtection -Policy $Policy -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName
            }
        }
     }
}
else
{
  Write-Output "Some Of Recovery Vault Parameters are Missing. Please Enter Recovery Vault Name, ResourceGroup and Policy"
}
