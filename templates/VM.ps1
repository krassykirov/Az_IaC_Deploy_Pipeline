[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)]
$ENV                = "Dev",
[Parameter(Mandatory=$false)]
$SubscriptionName   = "Visual Studio Professional Subscription",
[Parameter(Mandatory=$false)]
$ResourcegName      = "VMS",
[Parameter(Mandatory=$false)]
$vnetname           = "VNET2",
[Parameter(Mandatory=$false)]
$vnetRGname         = "NetworkRG",
[Parameter(Mandatory=$false)]
$Subnet             = "VNET2-Subnet",
[Parameter(Mandatory=$false)]
$ComputerName       = "TestAutomVM",
[Parameter(Mandatory=$false)][int]$AvsetNum,
[Parameter(Mandatory=$false)]
$ComputerSize       = "Standard_B1s",
[Parameter(Mandatory=$false)]
$OSSKU              = "2016-Datacenter",
[Parameter(Mandatory=$false)]
$FuncDescription    = "SQL Cluster",
[Parameter(Mandatory=$false)]
$ApplicationContact = "krassy@krassy.Com",
[Parameter(Mandatory=$false)]
$AppOwnerGroupName  = "Krassy InvITE",
[Parameter(Mandatory=$false)][int]$Disk_1_Size,
[Parameter(Mandatory=$false)][int]$Disk_2_Size,  
[Parameter(Mandatory=$false)][int]$Disk_3_Size,
[Parameter(Mandatory=$false)][int]$Disk_4_Size,
[Parameter(Mandatory=$false)][int]$Disk_5_Size

)

$cred = Get-AutomationPSCredential -Name "PythonApp"
Connect-AzAccount -Credential $cred -tenant "8da509ca-6966-41bb-a4ad-13477d4b0fdb" -ServicePrincipal

#setting variables
$SPNID = "6b00e15f-ac07-4f91-9ffe-0442e6fac969"
$DiskType            = "Standard_LRS"    
$TimeZone            = "Central European Standard Time" 
$Location            = 'westeurope'
$keyDestination      = 'Software'

$Prefix = $SubscriptionName.Replace(' ',"").Split("-")[-1].substring(0,6) 

$SAname  = 'krassysgfff' 
$AVSET  = 'DE-'+ $ENV +"-avset-" + $Prefix + $AvsetNum
$keyVaultName = 'DE-'+ $ENV +"-KV-$Prefix" + "-SSE01"
$DiskEncryptionSetName = 'DE-'+ $ENV + "-DES-"+ "$Prefix" +"01"
$keyName = 'DE'+ $ENV + "IaaS-key01" 

 $LUNs = @()

if($Disk_1_Size){
    $LUNs +=   "D;Disk1;$Disk_1_Size;readwrite;64K"
     }
if($Disk_2_Size){
    $LUNs +=   "E;Disk2;$Disk_2_Size;readwrite;64K"
}   
if($Disk_3_Size){
    $LUNs +=   "G;Disk3;$Disk_3_Size;readwrite;64K"
} 
if($Disk_4_Size){
    $LUNs +=   "F;Disk4;$Disk_4_Size;readwrite;64K"
} 
if($Disk_5_Size){
    $LUNs +=   "H;Disk5;$Disk_5_Size;readwrite;64K"
}   
     
              $Domain = "krassy.com"                # Set the domain correctly.
              $ComputerNIC = "nic_$ComputerName"
              # DNS for Development
             
              $DNS = @("10.10.10.10";"10.10.10.11";"10.10.10.12") 
              # Prepare tags for resources
              $tag_data = @{
                    AppOwnerGroupName = $AppOwnerGroupName
                    DomainName = "$Domain"
                    FunctionalDescription = $FuncDescription
                    ApplicationContact = $ApplicationContact
                 }
               #Validation block
              
              $ErrorActionPreference = 'Stop'

              
        #Select necessary subscription
        try
        {
            $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
            Select-AzSubscription $SubscriptionName

        }
        catch
        {
            Write-Error -Message "Unable to select Azure subscription. Details: $_" -ErrorAction Stop
        }
        #$Computername validation
        $FndResource = Get-AzResource -Name $ComputerName
        if ($FndResource) 
        {
            Write-Error "Resource with name $($FndResource.name) was found and belongs to type $($FndResource.resourcetype)"
            Break
        }
        #Collect VNET information
            try
            {
                $VNet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRGname
                $vnetname = $VNet.Name
                $vnetRGname = $VNet.ResourceGroupName
                $SelectedVnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRGname
            }
            catch
            {
                Write-Error -Message "Unable to get VNET configuration. Details: $_" -ErrorAction Stop
            }
 
              if ($Subnet -eq $null) 
              {
                    Write-Error -Message "Unable to select required subnet for deployment. Please verify input parameters" -ErrorAction Stop
              }
         
         
         # Create resource group if necessary
         $Location = $SelectedVNet.Location
         if (!(Get-AzResourceGroup -Name $ResourcegName -ErrorAction SilentlyContinue)) 
         {
            Write-host "Creating resource group : $ResourcegName"
            try 
            {
                New-AzResourceGroup -Name $ResourcegName -Location $Location -Tag $tag_data
            }
            catch
            {
                Write-Error -Message "Unable to create Resource group. Details: $_" -ErrorAction Stop
            }
         }
         else 
         { 
         Write-Host "Resource Group is already exist : $ResourcegName" 
         }
         
            Write-Host "Start with building server - $ComputerName"
            Write-Host "Create NIC - $ComputerName - $ComputerNIC"
           
           #creating nic configuration
           $Subnetsrv    = Get-AzVirtualNetworkSubnetConfig -Name $Subnet -VirtualNetwork $SelectedVnet
           try 
            {
                $nic = New-AzNetworkInterface -Name $ComputerNIC -ResourceGroupName $ResourcegName -Location $Location -Subnet $Subnetsrv -DnsServer $DNS -Tag $tag_data
            }
            catch
            {
                Write-Error -Message "Unable to create NIC. Details: $_" -ErrorAction Stop
            }                                           
                           
            #Creating local administrator account
                          
            $Password = "P@ssword999&^*"
            $secpassword = convertto-securestring "$Password" -asplaintext -force
            $username = "k1_" + $ComputerName
            $creds = New-Object System.Management.Automation.PSCredential($username, $secpassword)
            Write-Host "Set all for VM"
            #Creating AV set if necessary
            If($avsetnum)
            {
                Write-host "Availability set was required"
                    try 
                    {
                        New-AzAvailabilitySet -ResourceGroupName $ResourcegName -Name  $AVSET -Location $Location -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 5
                    }
                    catch
                    {
                        Write-Error -Message "Unable to create Availability set. Details: $_" -ErrorAction Stop
                    }     
                    
                $AVSET= Get-AzAvailabilitySet -ResourceGroupName $ResourcegName -Name $AVSET
                Update-AzAvailabilitySet -AvailabilitySet $AVSET -Sku Aligned 
                #sleep 50  #To validate why global set it here
            }
            else 
            {
            Write-host "Availability set is not requested"
            }
            $vm = ""
            If($avsetnum)
            {
                $vm = New-AzVMConfig -VMName $ComputerName -VMSize $ComputerSize -AvailabilitySetId $AVSET.Id
            }
            else
            {
                $vm = New-AzVMConfig -VMName $ComputerName -VMSize $ComputerSize
            }
            
            # Creation of SA for BootDiag with Subnet binding
              $BDstorage = Get-AzStorageAccount -Name $SAname -ResourceGroupName $ResourcegName -ErrorAction SilentlyContinue           

                If ($BDstorage)
                    {
                        Write-host "Getting existing SA for Boot Diagnostics"
                    }
                else
                {
             
                  #Enable Service Endpoint on the Subnet first!
              
                  if ((((Get-AzVirtualNetworkSubnetConfig -VirtualNetwork (Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRGname) -Name $Subnet).ServiceEndpoints.service)) -like "Microsoft.Storage")
                  {
                  
                  $networkset = (@{virtualNetworkRules=(@{VirtualNetworkResourceId="/subscriptions/$($Subscription.Id)/resourceGroups/$vnetRGname/providers/Microsoft.Network/virtualNetworks/$vnetname/subnets/$Subnet";Action="allow"}); defaultAction="Deny"}) 
                  $BDstorage = New-AzStorageAccount -ResourceGroupName $ResourcegName -AccountName $SAname.ToLower() -Location westeurope -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot -NetworkRuleSet $networkset -EnableHttpsTrafficOnly $true -MinimumTlsVersion TLS1_2 -AllowBlobPublicAccess $false -AllowSharedKeyAccess $true              
                  }
                  else 
                  {
                    Write-Error "Service endpoint does not exist" -ErrorAction Stop
                  }
                }
          
      try{      
  
            If(!(Get-AzResource -Name $keyVaultName -ErrorAction SilentlyContinue))
            {   
                Write-Output "Creating Key Vault, Encryption Key and Disk Encryption Set"
                $keyVault = New-AzKeyVault -Name $keyVaultName -ResourceGroupName $ResourcegName -Location $Location -EnabledForDiskEncryption -EnablePurgeProtection -SoftDeleteRetentionInDays 7
                Set-AzKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $SPNID -PermissionsToKeys wrapkey,unwrapkey,get,create, delete, list, update, import
                $key = Add-AzKeyVaultKey -VaultName $keyVault.VaultName -Name $keyName -Destination $keyDestination 

                New-AzResourceGroupDeployment -ResourceGroupName $ResourcegName `
                    -TemplateUri "https://raw.githubusercontent.com/Azure-Samples/managed-disks-powershell-getting-started/master/AutoKeyRotation/CreateDiskEncryptionSetWithAutoKeyRotation.json" `
                    -diskEncryptionSetName $DiskEncryptionSetName `
                    -keyVaultId $keyVault.ResourceId `
                    -keyVaultKeyUrl $key.Id `
                    -encryptionType "EncryptionAtRestWithCustomerKey" `
                    -region WestEurope 
                
                $DiskEncryptionSet = Get-AzDiskEncryptionSet -Name $DiskEncryptionSetName 
                Set-AzKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $DiskEncryptionSet.Identity.PrincipalId -PermissionsToKeys wrapkey,unwrapkey,get
            }
            else 
            {
                Write-Output "Key Vault $keyVaultName exist" 
                $keyVault = Get-AzKeyVault -VaultName $keyVaultName
                $diskEncryptionSet = Get-AzDiskEncryptionSet -Name $diskEncryptionSetName -ResourceGroupName $ResourcegName
              }
        }
        catch
        {
            Write-Output $Error[0] | fl * -Force
        }

                          
            $vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $ComputerName -Credential $creds -ProvisionVMAgent -EnableAutoUpdate -TimeZone $TimeZone
            $vm = Set-AzVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer "WindowsServer" -Skus $OSSKU -Version latest
            $vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
            $vm = Set-azVMOSDisk -VM $vm -Name "$ComputerName-C-Systemdisk" -StorageAccountType Standard_LRS -DiskEncryptionSetId $diskEncryptionSet.Id -CreateOption fromImage
            $vm = Set-AzVMBootDiagnostic -VM $vm -Enable -StorageAccountName $BDstorage.StorageAccountName -ResourceGroupName $ResourcegName
            #Prepare config data and disks for VM creation
            $LUNnum = 0
            foreach ($Disktocreate in $LUNs) 
            {
                $LUNnum++
                $SpecDisk = $Disktocreate.Split(";")
                $disklabel =  $SpecDisk[1]
                $diskdrive =  $SpecDisk[0]
                $disksize  =  $SpecDisk[2]
                $diskcache  =  $SpecDisk[3]
                $datadskconfig = New-AzDiskConfig -DiskSizeGB $disksize -Location $Location -Tag $tag_data -CreateOption Empty
                $Managed_Disk_Data = New-Azdisk -Name "$ComputerName-$disklabel" -ResourceGroupName $ResourcegName -Disk $datadskconfig 
             
                $vm = Add-AzVMDataDisk -VM $vm  -Name  "$ComputerName-$disklabel" -Lun $LUNnum -CreateOption Attach -Caching $diskcache -ManagedDiskId $Managed_Disk_Data.Id -DiskEncryptionSetId $diskEncryptionSet.Id
            }      
            
            Write-Host "Start creation"

            #Start VM creation 
            $output = New-AzVM -ResourceGroupName $ResourcegName -Location $Location -VM $vm -DisableBginfoExtension -LicenseType "Windows_Server"
            $output
            #Adding tags on the VM and change NIC settings
            If($output.IsSuccessStatusCode)
            {
                Write-Host "Wrting tagging information on resources"
                Set-AzResource -ResourceName $ComputerName -ResourceType "Microsoft.Compute/virtualmachines" -ResourceGroupName $ResourcegName -Tag $tag_data -Force
                $Update_tag_osdisk = Get-AzDisk -ResourceGroupName $ResourcegName -DiskName "$ComputerName-C-Systemdisk"
                Write-Host "Changing NIC settings to static"
                $nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
                Set-AzNetworkInterface -NetworkInterface $nic
                Set-AzResource -ResourceId $Update_tag_osdisk.Id -Tag $tag_data -Force
            }



