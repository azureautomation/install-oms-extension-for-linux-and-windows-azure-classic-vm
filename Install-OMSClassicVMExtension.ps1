<#  
.SYNOPSIS  
Installs OMS extension for Linux and Windows Azure classic VM.

.DESCRIPTION  
Installs OMS extension for Linux and Windows Azure classic VM. The Runbook takes Subscription Id and 
installs OMS Agent the VMs in the subscription.
The runbook needs classic run as connection string to access VM in other subscriptions.

.EXAMPLE
.\Install-OMSClassicVMExtension

.NOTES
AUTHOR: Azure Automation Team
LASTEDIT: 2017.06.22
#>

[OutputType([String])]

param (
    [Parameter(Mandatory=$false)] 
    [String]  $ConnectionAssetName = "AzureClassicRunAsConnection",
    [Parameter(Mandatory=$true)] 
    [String] $VMName,
    [Parameter(Mandatory=$true)] 
    [String] $subId,
    [Parameter(Mandatory=$true)] 
    [String] $subscriptionName,
    [Parameter(Mandatory=$true)] 
    [String] $ServiceName,
    [Parameter(Mandatory=$true)] 
    [String] $workspaceId,
    [Parameter(Mandatory=$true)] 
    [String] $workspaceKey
)

# Authenticate to Azure with certificate
Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
$Conn = Get-AutomationConnection -Name $ConnectionAssetName 
if ($Conn -eq $null) 
{
    throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
}

$CertificateAssetName = $Conn.CertificateAssetName
Write-Verbose "Getting the certificate: $CertificateAssetName" -Verbose
$AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
if ($AzureCert -eq $null) 
{
    throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
}


Write-Verbose "Authenticating to Azure with certificate." -Verbose
Set-AzureSubscription -SubscriptionId $subId -SubscriptionName $subscriptionName -Certificate $AzureCert 

Write-Output "Selecting Subscription $($subId)"
Select-AzureSubscription -SubscriptionId $subId

# If there is a specific resource group, then get all VMs in the resource group,
$VM = Get-AzureVM -Name $VMName -ServiceName $ServiceName

if($VM -eq $null) 
{
    throw "VM $($VMName) not found in ServiceName $($ServiceName)" 
}
 
if ($VM.VM.ProvisionGuestAgent -eq $false) 
{
    $VM.VM.ProvisionGuestAgent = $true
    Update-AzureVM -Name $VMName -ServiceName $ServiceName
}

$ExtentionNameAndTypeValue = 'MicrosoftMonitoringAgent'

if ($VM.VM.OSVirtualHardDisk.OS -eq "Linux") 
{
    $ExtentionNameAndTypeValue = 'OmsAgentForLinux'	
}

$error.Clear();

$Rtn = Set-AzureVMExtension -VM $VM -Publisher 'Microsoft.EnterpriseCloud.Monitoring' -ExtensionName $ExtentionNameAndTypeValue -Version '1.*' -PublicConfiguration "{'workspaceId': '$workspaceId'}" -PrivateConfiguration "{'workspaceKey': '$workspaceKey' }" | Update-AzureVM -Verbose

$retryCount=0;

while($error[0].Exception -ne $null -and $error[0].Exception.Message.Contains("ConflictError") -and $retryCount -le 5)
{
    Start-Sleep -Seconds 180
    $Rtn = Set-AzureVMExtension -VM $VM -Publisher 'Microsoft.EnterpriseCloud.Monitoring' -ExtensionName $ExtentionNameAndTypeValue -Version '1.*' -PublicConfiguration "{'workspaceId': '$workspaceId'}" -PrivateConfiguration "{'workspaceKey': '$workspaceKey' }" | Update-AzureVM -Verbose
    $retryCount = $retryCount + 1;        
}

if ($Rtn -eq $null) 
{
    Write-Output ($VM.Name + " did not add extension")
    Write-Error ($VM.Name + " did not add extension") -ErrorAction Continue
    Write-Error (ConvertTo-Json $Rtn) -ErrorAction Continue
    throw "Failed to add extension on VM $($VM.Name)"
}
else 
{
    Write-Output ($VM.Name + " Extension has been deployed")
}