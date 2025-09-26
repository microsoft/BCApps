Param(
    [Hashtable]$parameters
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

function Invoke-ContosoDemoTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-NavDefaultCompanyName),
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
    # Log all companies in the container
    $companies = Get-CompanyInBcContainer -containerName $parameters.ContainerName 
    $companies | Foreach-Object { Write-Host "Company: $($_.CompanyName)" }

    # Check if these is a company names something with cronus
    $cronusCompany = $companies | Where-Object { $_.CompanyName -match "cronus" } | Select-Object -First 1
    if ($cronusCompany) {
        Write-Host "Using company $($cronusCompany.CompanyName) for demo data generation"
        return $cronusCompany.CompanyName
    }
    Write-Host "Using default company CRONUS International Ltd. for demo data generation"
    return "CRONUS International Ltd."
}

# Reinstall all the uninstalled apps in the container
# This is needed to ensure that the various Demo Data apps are installed in the container when we generate demo data
$allUninstalledApps = Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesFirst | Where-Object { $_.IsInstalled -eq $false }
Install-AppFromContainer -ContainerName $parameters.ContainerName -AppsToInstall $allUninstalledApps.Name
# Log all the installed apps
foreach ($app in (Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
    Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - $($app.IsInstalled) / $($app.IsPublished)"
}

# Generate demo data in the container
Invoke-ContosoDemoTool -ContainerName $parameters.ContainerName