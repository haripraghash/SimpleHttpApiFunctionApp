Param (
	# Azure AD
	[Parameter(Mandatory=$true)]
    [string] $DeploymentServicePrincipalAppId,

	[Parameter(Mandatory=$true)]
    [secureString] $DeploymentServicePrincipalSecret,
	
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
	[string] $ShortLocation = ''
)

$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

$AadTenantId = (Get-AzContext).Tenant.Id
$ArtifactsStorageAccountName = $ResourceNamePrefix + $Environment + 'artifacts'
$ArtifactsStorageContainerName = 'artifacts'
$ArtifactsStagingDirectory = '.'

function CreateResourceGroup() {
	$parameters = New-Object -TypeName Hashtable

	# general
	$parameters['environment'] = $Environment
	#$parameters['isDevelopment'] = $IsDevelopment
	$parameters['shortLocation'] = $ShortLocation


	.\Deploy-AzureResourcegroup.ps1 `
	    -resourcegrouplocation $ResourceGroupLocation `
		-resourcegroupname $ResourceGroupName `
		-uploadartifacts `
		-storageaccountname $ArtifactsStorageAccountName `
		-storagecontainername $ArtifactsStorageContainerName `
		-templatefile $TemplateFile `
		-templateparameters $parameters
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