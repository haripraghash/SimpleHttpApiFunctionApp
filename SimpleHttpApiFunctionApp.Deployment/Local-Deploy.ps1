$applicationName = "SimpleHttpApiFunctionApp-Feature-Env-Deployment"
$displayName = "SimpleHttpApiFunctionApp-Feature-Env-Deployment"
$subscriptionId = "ce38cf7c-3580-4375-b891-13a38abb98be"
$password = ConvertTo-SecureString "test#123test" -AsPlainText -Force
$spnRole = "contributor"
$homePage = "http://" + $displayName
$identifierUri = $homePage
$resourceGroupName = "SimpleHttpApiFunction-feature-resgrp"
$location = "northeurope"
$azureSubscription = Get-AzSubscription -SubscriptionId $subscriptionId
$tenantId = $azureSubscription.TenantId
$id = $azureSubscription.Id

#Check if the application already exists
$app = Get-AzADApplication -IdentifierUri $homePage

if (![String]::IsNullOrEmpty($app) -eq $true)
{
    $appId = $app.ApplicationId
    Write-Output "An Azure AAD Appication with the provided values already exists, skipping the creation of the application..."
}
else
{
    # Create a new AD Application
    Write-Output "Creating a new Application in AAD (App URI - $identifierUri)" -Verbose
    $azureAdApplication = New-AzADApplication -DisplayName $displayName -HomePage $homePage -IdentifierUris $identifierUri -Password $password  -Verbose
    $appId = $azureAdApplication.ApplicationId
    Write-Output "Azure AAD Application creation completed successfully (Application Id: $appId)" -Verbose
}

$spn = Get-AzADServicePrincipal -ServicePrincipalName $appId

if (![String]::IsNullOrEmpty($spn) -eq $true)
{
   Write-Output "An Azure AAD Appication Principal for the application already exists, skipping the creation of the principal..."
}
else
{
    # Create new SPN
    Write-Output "Creating a new SPN" -Verbose
    $spn = New-AzADServicePrincipal -ApplicationId $appId
    $spnName = $spn.ServicePrincipalNames
    Write-Output "SPN creation completed successfully (SPN Name: $spnName)" -Verbose
    
    Write-Output "Waiting for SPN creation to reflect in Directory before Role assignment"
    Start-Sleep 30
}

 $rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue         

        if ([String]::IsNullOrEmpty($rg) -eq $true)
        {
            
                Write-Output "The ResourceGroup $resourceGroupName was NOT found, CREATING it..."
                New-AzResourceGroup -Name $resourceGroupName -Location $location
            
            
        }

        # Check if the role is already assigned
        $role = Get-AzRoleAssignment -ServicePrincipalName $appId -RoleDefinitionName $spnRole -ResourceGroupName $resourceGroupName
        
        if (![String]::IsNullOrEmpty($role) -eq $true)
        {
            Write-Output "The AAD Appication Principal already has the role $spnRole assigned to ResourceGroup $resourceGroupName, skipping role assignment..."
        }
        else
        {
            # Assign role to SPN to the provided ResourceGroup
            Write-Output "Assigning role $spnRole to SPN App $appId and ResourceGroup $resourceGroupName" -Verbose
            New-AzRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $appId -ResourceGroupName $resourceGroupName
            Write-Output "SPN role assignment completed successfully" -Verbose
        }

		.\Deploy-SimpleHttpApiFunction.ps1 -DeploymentServicePrincipalAppId $appId `
		-DeploymentServicePrincipalSecret $password `
		-ResourceGroupLocation 'northeurope' `
		-ShortLocation 'eun' 