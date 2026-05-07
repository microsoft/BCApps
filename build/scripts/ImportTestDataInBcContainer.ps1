Param(
    [Hashtable]$parameters
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1
Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

<#
.SYNOPSIS
    Forces a schema sync of all installed apps on all operational tenants.
.DESCRIPTION
    BC creates some SQL objects (e.g. preview number sequences used by posting-preview tests)
    lazily during schema sync. After cloning tenant databases, those objects can be missing,
    which causes errors like:
        Invalid object name 'dbo.$SEQ$NumberSequence$PreviewTableSeq32$CRONUS International Ltd_'
    when test code invokes posting preview. Running Sync-NAVApp -Mode ForceSync ensures the
    objects are created for every tenant before tests run.
.PARAMETER ContainerName
    Name of the BC container to sync apps in.
#>
function Sync-AppsAcrossTenants {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    Write-Host "Syncing all apps across all tenants (ForceSync) to ensure schema objects are created..."
    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        $tenants = @(Get-NAVTenant -ServerInstance $ServerInstance | Where-Object { $_.State -eq "Operational" } | ForEach-Object { $_.Id })
        Write-Host "Operational tenants: $($tenants -join ', ')"

        foreach ($tenant in $tenants) {
            Write-Host "Syncing apps for tenant '$tenant'..."
            $apps = Get-NAVAppInfo -ServerInstance $ServerInstance -Tenant $tenant
            foreach ($app in $apps) {
                try {
                    Sync-NAVApp -ServerInstance $ServerInstance -Tenant $tenant -Name $app.Name -Version $app.Version -Mode ForceSync -Force -ErrorAction Stop | Out-Null
                } catch {
                    Write-Host "  WARNING: Sync failed for '$($app.Name)' v$($app.Version) on tenant '$tenant': $($_.Exception.Message)"
                }
            }
        }
    }
    Write-Host "App sync across tenants complete."
}

<#
.SYNOPSIS
    Creates additional tenants by cloning the default tenant database.
.DESCRIPTION
    Stops the BC server, copies the default tenant database for each additional tenant,
    restarts the server, and mounts the new databases as tenants. Each new tenant is an
    exact clone of the default tenant including all apps and demo data.
    Only runs if the container is configured for multitenancy.
.PARAMETER ContainerName
    Name of the BC container to create tenants in.
.PARAMETER NumberOfTenants
    Total number of tenants to have in the container, including the default tenant.
    Must be >= 1. If 1, no additional tenants are created.
#>
function New-AdditionalTenants {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [int]$NumberOfTenants
    )

    if ($NumberOfTenants -le 1) {
        Write-Host "NumberOfTenants is $NumberOfTenants. No additional tenants will be created."
        return
    }

    if (-not (Test-IsMultitenant -ContainerName $ContainerName)) {
        Write-Host "Container is not multitenant. Skipping additional tenant creation."
        return
    }

    Write-Host "Container is multitenant. Creating $($NumberOfTenants - 1) additional tenant(s) for a total of $NumberOfTenants..."

    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($numberOfTenants)
        $sourceDatabaseName = "default"

        Write-Host "Stopping server to copy tenant database..."
        Stop-NAVServerInstance -ServerInstance $ServerInstance

        $copiedDatabases = @()
        for ($i = 2; $i -le $numberOfTenants; $i++) {
            $newDatabaseName = "tenant$i"
            try {
                Write-Host "Copying database '$sourceDatabaseName' to '$newDatabaseName'..."
                Copy-NAVDatabase -SourceDatabaseName $sourceDatabaseName -DestinationDatabaseName $newDatabaseName -DatabaseServer "."
                $copiedDatabases += $newDatabaseName
            }
            catch {
                Write-Host "WARNING: Failed to copy database for '$newDatabaseName': $($_.Exception.Message). Continuing without this tenant."
            }
        }

        Write-Host "Starting server..."
        Start-NAVServerInstance -ServerInstance $ServerInstance

        foreach ($newDatabaseName in $copiedDatabases) {
            try {
                Write-Host "Mounting tenant '$newDatabaseName'..."
                Mount-NAVTenant -ServerInstance $ServerInstance -Id $newDatabaseName -DatabaseServer "." -DatabaseName $newDatabaseName -OverwriteTenantIdInDatabase -Force
            }
            catch {
                Write-Host "WARNING: Failed to mount tenant '$newDatabaseName': $($_.Exception.Message). Continuing without this tenant."
            }
        }

        Write-Host "All tenants:"
        Get-NAVTenant -ServerInstance $ServerInstance | ForEach-Object {
            Write-Host "  Tenant: $($_.Id) - State: $($_.State)"
        }
    } -argumentList $NumberOfTenants

    # Wait for the newly mounted tenants to reach Operational state before returning
    Wait-ForTenantReady -ContainerName $ContainerName
}

<#
.SYNOPSIS
    Tests whether a BC container is configured for multitenancy.
.PARAMETER ContainerName
    Name of the BC container to check.
.OUTPUTS
    [bool] True if the container is multitenant, false otherwise.
#>
function Test-IsMultitenant {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    return ((Get-BcContainerServerConfiguration -ContainerName $ContainerName).Multitenant -eq 'true')
}

<#
.SYNOPSIS
    Waits for all tenants in a multitenant BC container to finish mounting.
.DESCRIPTION
    Polls the tenant state inside the container using Get-NavTenant until no tenants
    are in the "Mounting" state. Required after service tier restarts in multitenant
    containers, as tenants may not be immediately accessible.
.PARAMETER ContainerName
    Name of the BC container to check tenant state in.
#>
function Wait-ForTenantReady {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    Write-Host "Waiting for tenants to be ready..."
    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        $maxWait = 300
        $waited = 0
        while (Get-NavTenant $ServerInstance | Where-Object { $_.State -eq "Mounting" }) {
            Write-Host "Tenants still mounting... ($waited seconds)"
            Start-Sleep -Seconds 5
            $waited += 5
            if ($waited -ge $maxWait) {
                throw "Tenants still mounting after $maxWait seconds"
            }
        }
        Write-Host "All tenants ready."
    }
}

function Invoke-ContosoDemoTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-TestCompanyName),
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

function Invoke-LegacyDemoDataTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-TestCompanyName)
    )

    # Allow access to configuration packages
    Set-BcContainerServerConfiguration -ContainerName $ContainerName -keyName EnforceUserPathForAlFileOperations -keyValue $false
    Restart-BcContainerServiceTier -ContainerName $ContainerName
    Wait-ForTenantReady -ContainerName $ContainerName

    Write-Host "Initializing company"
    Invoke-NavContainerCodeunit -Codeunitid 2 -containerName $ContainerName -CompanyName $CompanyName

    # Use the W1.ENU rapidstart from the BC platform artifacts. The platform package always
    # uses W1.ENU regardless of the container's localization. Search C:\ directly so we don't
    # have to track BC version-specific paths.
    $rapidstartFile = Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        $found = Get-ChildItem -Path "C:\" -Recurse -Filter "NAV*.W1.ENU.EXTENDED.rapidstart" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $found) {
            throw "Could not find any NAV*.W1.ENU.EXTENDED.rapidstart anywhere under C:\."
        }
        $found.FullName
    }

    Write-Host "Importing configuration package: $rapidstartFile"
    Invoke-NavContainerCodeunit -Codeunitid 8620 -containerName $ContainerName -CompanyName $CompanyName -MethodName "ImportAndApplyRapidStartPackage" -Argument $rapidstartFile
}

function Get-TestCompanyName() {
    $companyName = Get-ALGoSetting -Key "companyName"
    if ([string]::IsNullOrEmpty($companyName)) {
        return "CRONUS International Ltd." # Fallback in case no company name is specified in settings
    } else {
        return $companyName
    }
}

function Invoke-DemoDataGeneration
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [ValidateSet("UnitTest","IntegrationTest","Uncategorized","Legacy")]
        [string]$TestType
    )
    if ($TestType -eq "UnitTest") {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "UnitTest shouldn't have dependency on any Demo Data, skipping demo data generation"
        return
    } elseif( $TestType -eq "IntegrationTest" ) {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "Proceeding with demo data generation (SetupData) as test type is set to IntegrationTest"
        Invoke-ContosoDemoTool -ContainerName $ContainerName -SetupData
    } elseif( $TestType -eq "Uncategorized" ) {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName) -EvaluationCompany
        Write-Host "Proceeding with full demo data generation as test type is set to Uncategorized"
        Invoke-ContosoDemoTool -ContainerName $ContainerName
    } elseif ( $TestType -eq "Legacy" ) {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "Proceeding with full demo data generation as test type is set to Legacy"
        Invoke-LegacyDemoDataTool -ContainerName $ContainerName
    }
    else {
        throw "Unknown test type $TestType."
    }

}

function New-TestCompany() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$CompanyName,
        [Parameter(Mandatory=$false)]
        [switch]$EvaluationCompany
    )

    # Delete existing companies in the container
    $existingCompanies = Get-CompanyInBcContainer -containerName $ContainerName
    foreach ($company in $existingCompanies) {
        Write-Host "Deleting company $($company.CompanyName) in container $ContainerName"
        Remove-CompanyInBcContainer -containerName $ContainerName -companyName $company.CompanyName
    }

    Write-Host "Creating new test company in container $ContainerName"
    New-CompanyInBcContainer -containerName $ContainerName -companyName $CompanyName -evaluationCompany:$EvaluationCompany
}

# Log all the installed apps
foreach ($app in (Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
    Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - $($app.IsInstalled) / $($app.IsPublished)"
}

Wait-ForTenantReady -ContainerName $parameters.ContainerName

try {
    Invoke-DemoDataGeneration -ContainerName $parameters.ContainerName -TestType (Get-ALGoSetting -Key "testType")
} catch {
    Write-Host "An error occurred during demo data generation: $($_.Exception.Message)"
    Write-Host "Trying again..."
    Invoke-DemoDataGeneration -ContainerName $parameters.ContainerName -TestType (Get-ALGoSetting -Key "testType")
}

# Create additional tenants by cloning the default tenant (which now has all apps + demo data)
# Number of tenants (including default) can be overridden via "numberOfTenantsForTesting" in AL-Go settings; defaults to 3
$numberOfTenants = Get-ALGoSetting -Key "numberOfTenantsForTesting"
if ($null -eq $numberOfTenants -or $numberOfTenants -lt 1) {
    throw "AL-Go setting 'numberOfTenantsForTesting' is missing or invalid. Set it to a positive integer in .github/AL-Go-Settings.json."
}
New-AdditionalTenants -ContainerName $parameters.ContainerName -NumberOfTenants $numberOfTenants

# Force-sync apps on every tenant so lazy schema objects (e.g. posting-preview number sequences)
# are created before tests run. Without this, SCM Item Journal Post Preview tests fail with
# "Invalid object name 'dbo.$SEQ$NumberSequence$PreviewTableSeq32$CRONUS International Ltd_'".
Sync-AppsAcrossTenants -ContainerName $parameters.ContainerName