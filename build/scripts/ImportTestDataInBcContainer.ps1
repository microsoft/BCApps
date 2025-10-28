Param(
    [Hashtable]$parameters
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

function Invoke-ContosoDemoTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-NavDefaultCompanyName -ContainerName $ContainerName),
        [switch]$SetupData = $false
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

# Generate demo data in the container
Invoke-ContosoDemoTool -ContainerName $parameters.ContainerName
