<#
.SYNOPSIS
    This script backs up an instance of APIM to a storage account
    
.DESCRIPTION
    This script backs up an instance of APIM to a storage account

.PARAMETER sourceResourceGroupName
    The resource group that the APIM instance and storage account reside in

.PARAMETER sourceApiManagementInstance
    The name of the APIM instance to backup

.PARAMETER storageAccountName
    The storage account to backup to

.PARAMETER storageContainerName
    The storage container to backup to
#>

param 
(
    [Parameter(Mandatory = $true)]
    [string] $sourceResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $sourceApiManagementInstance,

    [Parameter(Mandatory = $true)]
    [string] $storageAccountName,

    [Parameter(Mandatory = $true)]
    [string] $storageContainerName
)

$ErrorActionPreference = "Stop"

# Set up the zip file name to store in storage: $storageContainerName
$dateString =  Get-Date -UFormat "_%Y_%m_%d";
$BlobName = -join( $sourceResourceGroupName, "-", $sourceApiManagementInstance, $dateString, ".zip");
Write-Host "The name of the blob to be stored is: "$BlobName;

# get the storage account key
$StorageAccountKey = (Get-AzureRMStorageAccountKey -ResourceGroupName $sourceResourceGroupName -Name $storageAccountName)[0]; 

# get the context
$StorageAccountContext = New-AzureStorageContext -storageAccountName $storageAccountName -StorageAccountKey $StorageAccountKey.Value;
Write-Host "The blob endpoint is: "$StorageAccountContext.BlobEndPoint;
Write-Host "The storage account name is: "$StorageAccountContext.StorageAccountName;
Write-Host "The storage container name is: "$storageContainerName;

# make sure we create the storage container if it doesnt already exist
$existingContainer = Get-AzureStorageContainer -Context $StorageAccountContext | 
            Where-Object { $_.Name -like $storageContainerName }

if (!$existingContainer)
{
    "Could not find storage container '" + $storageContainerName + ". Creating it now....";
    $newContainer = New-AzureStorageContainer -Name $storageContainerName -Context $StorageAccountContext;
    "Storage container '" + $newContainer.Name + "' created.";
} else 
{
    "Storage container '" + $storageContainerName + "' already exists.";
}

# backup from source APIM instance
"Backing up APIM instance '" + $sourceApiManagementInstance + "' in resource group '" + $sourceResourceGroupName + "' to storage container name '" + $storageContainerName + "' and blob name '" + $BlobName  + "'";
$PsApiManagement = Backup-AzureRMApiManagement -Name $sourceApiManagementInstance -ResourceGroupName $sourceResourceGroupName -StorageContext $StorageAccountContext `
                       -TargetContainerName $storageContainerName                                                     `
                       -TargetBlobName      $BlobName                                                                           `
                       -Verbose -PassThru;
"The provisioning state is '" + $PsApiManagement.ProvisioningState + "'";



