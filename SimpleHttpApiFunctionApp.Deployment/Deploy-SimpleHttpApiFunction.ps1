Param (
	[Parameter(Mandatory=$true)]
    [string] $TenantId,
	
	# Resource group
	[Parameter(Mandatory=$true)]
	[string] $ResourceGroupLocation,

    [string] $ResourceGroupName = 'SimpleHttpApiFunction-feature-resgrp',

    [string] $TemplateFile = 'azuredeploy.json',

	# General
	[Parameter(Mandatory=$true)]
	[string] $Environment = 'feature',

	[bool] $IsDevelopment = $true,
	
	[Parameter(Mandatory=$true)]
	[string] $ShortLocation = '',

	[switch] $ValidateOnly
)

$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot
Write-Host "Begining to execute Deploy-SimpleHttpApiFunction.ps1"
$AadTenantId = (Get-AzContext).Tenant.Id
$ArtifactsStorageAccountName = 'httpapi' + $Environment + 'artifacts'
$ArtifactsStorageContainerName = 'artifacts'
$ArtifactsStagingDirectory = '.'


function CreateResourceGroup() {
	$parameters = New-Object -TypeName Hashtable

	# general
	$parameters['environment'] = $Environment
	#$parameters['isDevelopment'] = $IsDevelopment
	$parameters['shortLocation'] = $ShortLocation
	$parameters['resourceGroupLocation'] = $ResourceGroupLocation

if($ValidateOnly)
{

	.\Deploy-AzureResourceGroup.ps1 `
	    -ResourceGroupLocation $ResourceGroupLocation `
		-ResourceGroupName $ResourceGroupName `
		-UploadArtifacts `
		-StorageAccountName $ArtifactsStorageAccountName `
		-StorageContainerName $ArtifactsStorageContainerName `
		-TemplateFile $TemplateFile `
		-TemplateParameters $parameters `
		-ValidateOnly
	}
	else
	{
		.\Deploy-AzureResourceGroup.ps1 `
	    -ResourceGroupLocation $ResourceGroupLocation `
		-ResourceGroupName $ResourceGroupName `
		-UploadArtifacts `
		-StorageAccountName $ArtifactsStorageAccountName `
		-StorageContainerName $ArtifactsStorageContainerName `
		-TemplateFile $TemplateFile `
		-TemplateParameters $parameters 
	}
}

function CreateAzureAdApps()
{
    Write-Host "Azure AD App - Creating application..."

	$ClientPermissionNames = @("user_impersonation")

    $azureAdWebApp = .\AD\Add-AdApplication.ps1 `
        -TenantId $AadTenantId `
        -WebAppName $webUiName `
        -ApiAppName $webApiName `
		-HpUsersGroupId $HpUsersGroupId `
		-HpAdminsGroupId $HpAdminsGroupId `
		-AadAdmin $AadAdmin `
		-AadPassword $AadPassword `
		-ClientPermissionNames $ClientPermissionNames `
		-IsDevelopment $IsDevelopment
        
    Write-Host "Azure Ad App - Done."
    return $azureAdWebApp    
}

function Main() {
	$deployment = CreateResourceGroup
	$deployment

	if ($deployment.ProvisioningState -eq 'Failed'){
		throw "Deployment was unsuccessful"
	}
}

Main