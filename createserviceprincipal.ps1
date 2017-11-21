param
(
    [Parameter(HelpMessage="Enter Azure Subscription name. You need to be Subscription Admin to execute the script")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalOnly", Mandatory=$true)]
    [string] $subscriptionName,

    [Parameter(HelpMessage="Provide a name for the SPN that you would create")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalOnly", Mandatory=$true)]
    [string] $applicationName,

    [Parameter(HelpMessage="Provide a password for SPN application that you would create")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalOnly", Mandatory=$true)]
    [string] $password,

    [Parameter(HelpMessage="The ResourceGroup Name to apply the role")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [string[]] $resourceGroupNames,

    [Parameter(HelpMessage="Create the Resource Groups if they not exists")]    
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [switch] $createResourceGroups,

    [Parameter(HelpMessage="The location to create the Resource Groups")] 
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]   
    [string] $location,

    [Parameter(Mandatory=$false, HelpMessage="Provide a SPN role assignment")]
    [string] $spnRole = "contributor",

    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(HelpMessage="Grant the role on the whole subscription")]
    [switch] $grantRoleOnSubscriptionLevel,

    [Parameter(HelpMessage="The prefix voor de Application Name", Mandatory=$false)]
    [string] $applicationNamePrefix = "VSTS.",

    [Parameter(HelpMessage="The end datetime when the password expires, default 1/1/2099 1:00 AM", Mandatory=$false)]
    [datetime] $passwordExpirationDateTime = (Get-Date "1/1/2099 1:00 AM")
)

#Initialize
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$displayName = [String]::Format("$applicationNamePrefix{0}", $applicationName)
$homePage = "http://" + $displayName
$identifierUri = $homePage


# Initialize subscription
$isAzureModulePresent = Get-Module -Name AzureRM* -ListAvailable
if ([String]::IsNullOrEmpty($isAzureModulePresent) -eq $true)
{
    Write-Output "Script requires AzureRM modules to be present. Obtain AzureRM from https://github.com/Azure/azure-powershell/releases. Please refer https://github.com/Microsoft/vsts-tasks/blob/master/Tasks/DeployAzureResourceGroup/README.md for recommended AzureRM versions." -Verbose
    return
}


Import-Module -Name AzureRM.Profile

#When not already logged in, login
if (((get-azurermcontext).Account) -eq $null)
{
	Write-Output "Provide your credentials to access Azure subscription $subscriptionName" -Verbose	
	Login-AzureRmAccount -subscriptionname $subscriptionName
}

$azureSubscription = Get-AzureRmSubscription -SubscriptionName $subscriptionName
$tenantId = $azureSubscription.TenantId
$id = $azureSubscription.Id

#Check if the application already exists
$app = Get-AzureRmADApplication -IdentifierUri $homePage

if (![String]::IsNullOrEmpty($app) -eq $true)
{
    $appId = $app.ApplicationId
    Write-Output "An Azure AAD Appication with the provided values already exists, skipping the creation of the application..."
}
else
{
    # Create a new AD Application
    Write-Output "Creating a new Application in AAD (App URI - $identifierUri)" -Verbose
    $azureAdApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $homePage -IdentifierUris $identifierUri -Password $password -EndDate $passwordExpirationDateTime  -Verbose
    $appId = $azureAdApplication.ApplicationId
    Write-Output "Azure AAD Application creation completed successfully (Application Id: $appId)" -Verbose
}


# Check if the principal already exists
$spn = Get-AzureRmADServicePrincipal -ServicePrincipalName $appId

if (![String]::IsNullOrEmpty($spn) -eq $true)
{
   Write-Output "An Azure AAD Appication Principal for the application already exists, skipping the creation of the principal..."
}
else
{
    # Create new SPN
    Write-Output "Creating a new SPN" -Verbose
    $spn = New-AzureRmADServicePrincipal -ApplicationId $appId
    $spnName = $spn.ServicePrincipalNames
    Write-Output "SPN creation completed successfully (SPN Name: $spnName)" -Verbose
    
    Write-Output "Waiting for SPN creation to reflect in Directory before Role assignment"
    Start-Sleep 30
}

# Add the principal role to the Resource Groups (if provided)
if ($resourceGroupNames)
{
    foreach ($resourceGroupName in $resourceGroupNames)
    {
        $rg = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue         

        if ([String]::IsNullOrEmpty($rg) -eq $true)
        {
            if ($createResourceGroups)
            {
                Write-Output "The ResourceGroup $resourceGroupName was NOT found, CREATING it..."
                New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
            }
            else
            {
                Write-Output "The ResourceGroup $resourceGroupName was NOT found, skipping role assignment for this ResourceGroup..."
                continue
            }
        }

        # Check if the role is already assigned
        # If I use the parameter ResourceGroupName, it's not working correctly, it seems to apply a "like" search, so if I have
        # two resourceGroups, i.e. : Test and Test1, the "Get-AzureRmRoleAssignment -ResourceGroupName Test1" is getting both the roles for Test and Test1,
        # that's why I am using a where filtering
        # I have submitted an issue about this, see: https://github.com/Azure/azure-powershell/issues/3414
        $role = Get-AzureRmRoleAssignment -ServicePrincipalName $appId -RoleDefinitionName $spnRole | where {$_.Scope -eq [String]::Format("/subscriptions/{0}/resourceGroups/{1}", $id, $resourceGroupName)}

        if (![String]::IsNullOrEmpty($role) -eq $true)
        {
            Write-Output "The AAD Appication Principal already has the role $spnRole assigned to ResourceGroup $resourceGroupName, skipping role assignment..."
        }
        else
        {
            # Assign role to SPN to the provided ResourceGroup
            Write-Output "Assigning role $spnRole to SPN App $appId and ResourceGroup $resourceGroupName" -Verbose
            New-AzureRmRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $appId -ResourceGroupName $resourceGroupName
            Write-Output "SPN role assignment completed successfully" -Verbose
        }
    }
}

if ($grantRoleOnSubscriptionLevel)
{
    # Assign role to SPN to the whole subscription
    Write-Output "Assigning role $spnRole to SPN App $appId for subscription $subscriptionName" -Verbose
    New-AzureRmRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $appId 
    Write-Output "SPN role assignment completed successfully" -Verbose
}


# Print the values
Write-Output "`nCopy and Paste below values for Service Connection" -Verbose
Write-Output "***************************************************************************"
Write-Output "Subscription Id: $id"
Write-Output "Subscription Name: $subscriptionName"
Write-Output "Service Principal Client (Application) Id: $appId"
Write-Output "Service Principal key: <Password that you typed in>"
Write-Output "Tenant Id: $tenantId"
Write-Output "Service Principal Display Name: $displayName"
Write-Output "Service Principal Names:"
foreach ($spnname in $spn.ServicePrincipalNames)
{
    Write-Output "   *  $spnname"
}
Write-Output "***************************************************************************"
