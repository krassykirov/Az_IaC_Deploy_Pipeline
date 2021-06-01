[CmdletBinding()]
Param(

$VnetResourceGroupName,
$vNetName
  
)

Write-Host "Starting PeerVnet script"
Write-Host "ResourceGroupName variable value is: $VnetResourceGroupName"
Write-Host "vNetName variable value is: $vNetName"

$VNET1 = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $VnetResourceGroupName

$VNET3 = Get-AzVirtualNetwork -Name 'Vnet3' -ResourceGroupName 'NetworkRG'

Write-Host "Creating VNET Peering"

Add-AzVirtualNetworkPeering `
        -Name "VNET1-VNET3" `
        -VirtualNetwork $VNET1 `
        -RemoteVirtualNetworkId $VNET3.id 
        #-AllowForwardedTraffic  
        #-UseRemoteGateways 
        
Add-AzVirtualNetworkPeering `
        -Name "VNET3-VNET1" `
        -VirtualNetwork $VNET3 `
        -RemoteVirtualNetworkId $VNET1.Id
        #-AllowGatewayTransit  
