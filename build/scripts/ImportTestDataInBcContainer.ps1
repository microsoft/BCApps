Param(
    [Hashtable]$parameters
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1
Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Invoke-ContosoDemoTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-NavDefaultCompanyName -ContainerName $ContainerName),
        [switch]$SetupData
    )
    Write-Host "Initializing company in container $ContainerName"
    Invoke-NavContainerCodeunit -Codeunitid 2 -containerName $ContainerName -CompanyName $CompanyName

    if ($SetupData) {
        Write-Host "Generating Setup Demo Data in container $ContainerName"
        Invoke-NavContainerCodeunit -Codeunitid 5193 -containerName $ContainerName -CompanyName $CompanyName -MethodName "CreateSetupDemoData"
    } else {
        Write-Host "Generating All Demo Data in container $ContainerName"
        Invoke-NavContainerCodeunit -CodeunitId 5193 -containerName $containerName -CompanyName $CompanyName -MethodName "CreateAllDemoData"
        Invoke-NavContainerCodeunit -CodeunitId 5140 -containerName $containerName -CompanyName $CompanyName -MethodName "DeleteWarehouseEmployee"
    }

    Invoke-NavContainerCodeunit -CodeunitId 5691 -containerName $ContainerName -CompanyName $CompanyName
}

function Get-NavDefaultCompanyName
{
    param(
        [string]$ContainerName
    )
    # Log all companies in the container
    $companies = Get-CompanyInBcContainer -containerName $ContainerName
    $companies | Foreach-Object { Write-Host "Company: $($_.CompanyName)" }

    # Look for the Cronus company
    $cronusCompany = $companies | Where-Object { $_.CompanyName -match "CRONUS" } | Select-Object -First 1
    if ($cronusCompany) {
        Write-Host "Using company $($cronusCompany.CompanyName) for demo data generation"
        return $cronusCompany.CompanyName
    }

    # If no Cronus company is found, thow
    throw "No Cronus company found in container $ContainerName.."
}

function Invoke-DemoDataGeneration
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [ValidateSet("UnitTest","IntegrationTest","Uncategorized")]
        [string]$TestType
    )
    if ($TestType -eq "UnitTest") {
        Write-Host "UnitTest shouldn't have dependency on any Demo Data, skipping demo data generation"
        return
    } elseif( $TestType -eq "IntegrationTest" ) {
        Write-Host "Proceeding with demo data generation (SetupData) as test type is set to IntegrationTest"
        Invoke-ContosoDemoTool -ContainerName $ContainerName -SetupData -CompanyName "CRONUS IntegrationTest"
    } elseif( $TestType -eq "Uncategorized" ) {
        Write-Host "Proceeding with full demo data generation as test type is set to Uncategorized"
        Invoke-ContosoDemoTool -ContainerName $ContainerName -CompanyName "CRONUS Uncategorized"
    } else {
        throw "Unknown test type $TestType."
    }

}

# Delete existing companies in the container
$existingCompanies = Get-CompanyInBcContainer -containerName $parameters.ContainerName
foreach ($company in $existingCompanies) {
    Write-Host "Deleting company $($company.CompanyName) in container $($parameters.ContainerName)"
    Remove-CompanyInBcContainer -containerName $parameters.ContainerName -companyName $company.CompanyName
}

Write-Host "Creating new test company in container $($parameters.ContainerName)"
New-CompanyInBcContainer -containerName $parameters.ContainerName -companyName "CRONUS UnitTests" -evaluationCompany
New-CompanyInBcContainer -containerName $parameters.ContainerName -companyName "CRONUS IntegrationTest" -evaluationCompany
#New-CompanyInBcContainer -containerName $parameters.ContainerName -companyName "CRONUS UncategorizedTests" -evaluationCompany

# Reinstall all the uninstalled apps in the container
# This is needed to ensure that the various Demo Data apps are installed in the container when we generate demo data
$allUninstalledApps = Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesFirst | Where-Object { $_.IsInstalled -eq $false }
# Exclude language apps from being reinstalled
$allUninstalledApps = $allUninstalledApps | Where-Object { $_.Name -notmatch "^.+ language \(.+\)$" }

$failedToInstallApps = @(Install-AppInContainer -ContainerName $parameters.ContainerName -AppsToInstall $allUninstalledApps.Name)

if ($failedToInstallApps.Count -gt 0) {
    Write-Host "The following apps failed to install in the container: $($failedToInstallApps -join ", ")"
    throw "Failed to install apps: $($failedToInstallApps -join ", ")"
}

# Log all the installed apps
foreach ($app in (Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
    Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - $($app.IsInstalled) / $($app.IsPublished)"
}

Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName "EnableTaskScheduler" -keyValue false
Restart-BcContainerServiceTier -ContainerName $parameters.ContainerName

Invoke-DemoDataGeneration -ContainerName $parameters.ContainerName -TestType (Get-ALGoSetting -Key "testType")