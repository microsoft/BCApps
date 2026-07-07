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

    Write-Host "Stopping server to copy tenant database..."
    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        Stop-NAVServerInstance -ServerInstance $ServerInstance
    }

    $copiedDatabases = Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($numberOfTenants)
        $sourceDatabaseName = "default"
        $maxAttempts = 3
        $retryDelaySeconds = 5
        $copied = @()
        for ($i = 2; $i -le $numberOfTenants; $i++) {
            $newDatabaseName = "tenant$i"

            for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
                try {
                    Write-Host "Copying database '$sourceDatabaseName' to '$newDatabaseName' (attempt $attempt/$maxAttempts)..."
                    Copy-NAVDatabase -SourceDatabaseName $sourceDatabaseName -DestinationDatabaseName $newDatabaseName -DatabaseServer "." | Out-Null
                    break
                } catch {
                    Write-Host "WARNING: Copy of '$newDatabaseName' failed on attempt $attempt/${maxAttempts}: $($_.Exception.Message)"
                    if ($attempt -eq $maxAttempts) {
                        throw "Failed to copy database '$sourceDatabaseName' to '$newDatabaseName' after $maxAttempts attempts. Last error: $($_.Exception.Message)"
                    }
                    Write-Host "Retrying in $retryDelaySeconds seconds..."
                    Start-Sleep -Seconds $retryDelaySeconds
                }
            }

            $copied += $newDatabaseName
        }
        $copied
    } -argumentList $NumberOfTenants

    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($copiedDatabases)
        Write-Host "Starting server..."
        Start-NAVServerInstance -ServerInstance $ServerInstance

        foreach ($newDatabaseName in $copiedDatabases) {
            Write-Host "Mounting tenant '$newDatabaseName'..."
            Mount-NAVTenant -ServerInstance $ServerInstance -Id $newDatabaseName -DatabaseServer "." -DatabaseName $newDatabaseName -OverwriteTenantIdInDatabase -Force
        }

        Write-Host "All tenants:"
        Get-NAVTenant -ServerInstance $ServerInstance | ForEach-Object {
            Write-Host "  Tenant: $($_.Id) - State: $($_.State)"
        }
    } -argumentList (,$copiedDatabases)

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

function Backup-TenantDatabaseForDemoDataRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$BackupFile
    )

    Write-Host "Stopping server to snapshot tenant database before demo data generation..."
    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        Stop-NAVServerInstance -ServerInstance $ServerInstance
    }

    try {
        Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($backupFile)
            Import-Module SqlServer -ErrorAction Stop

            if (Test-Path $backupFile) {
                Remove-Item -Path $backupFile -Force
            }

            Write-Host "Backing up tenant database 'default' to '$backupFile'..."
            Backup-SqlDatabase -ServerInstance "." -Database "default" -BackupFile $backupFile -Initialize -ErrorAction Stop | Out-Null
        } -argumentList $BackupFile
    } finally {
        Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
            Start-NAVServerInstance -ServerInstance $ServerInstance
        }
        Wait-ForTenantReady -ContainerName $ContainerName
    }
}

function Restore-TenantDatabaseForDemoDataRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$BackupFile
    )

    # Restart the container to drop lingering connections to 'default' so the restore can obtain exclusive access.
    Write-Host "Restarting container to release lingering database connections before restoring snapshot..."
    Restart-BcContainer -containerName $ContainerName
    Wait-ForTenantReady -ContainerName $ContainerName

    Write-Host "Restoring tenant database from snapshot before retrying demo data generation..."
    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        Stop-NAVServerInstance -ServerInstance $ServerInstance
    }

    try {
        Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($backupFile)
            Import-Module SqlServer -ErrorAction Stop

            if (-not (Test-Path $backupFile)) {
                throw "Demo-data retry snapshot file '$backupFile' was not found."
            }

            Restore-SqlDatabase -ServerInstance "." -Database "default" -BackupFile $backupFile -ReplaceDatabase -ErrorAction Stop | Out-Null
        } -argumentList $BackupFile
    } finally {
        Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
            Start-NAVServerInstance -ServerInstance $ServerInstance
        }
        Wait-ForTenantReady -ContainerName $ContainerName
    }
}

function Remove-DemoDataRetryBackup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$BackupFile
    )

    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($backupFile)
        if (Test-Path $backupFile) {
            Remove-Item -Path $backupFile -Force
        }
    } -argumentList $BackupFile
}

function Invoke-ContosoDemoToolWithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$CompanyName,
        [switch]$SetupData
    )

    if (-not (Test-IsMultitenant -ContainerName $ContainerName)) {
        Invoke-ContosoDemoTool -ContainerName $ContainerName -CompanyName $CompanyName -SetupData:$SetupData
        return
    }

    $maxAttempts = 2
    $backupFile = "C:\ProgramData\BcContainerHelper\DemoDataRetry-default.bak"

    try {
        Backup-TenantDatabaseForDemoDataRetry -ContainerName $ContainerName -BackupFile $backupFile

        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            try {
                Invoke-ContosoDemoTool -ContainerName $ContainerName -CompanyName $CompanyName -SetupData:$SetupData
                return
            } catch {
                if ($attempt -eq $maxAttempts) {
                    throw
                }

                Write-Host "Demo data generation failed on attempt $attempt/$maxAttempts. Restoring tenant database snapshot before retrying."
                Restore-TenantDatabaseForDemoDataRetry -ContainerName $ContainerName -BackupFile $backupFile
            }
        }
    } finally {
        Remove-DemoDataRetryBackup -ContainerName $ContainerName -BackupFile $backupFile
    }
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

<#
.SYNOPSIS
    Runs the Contoso demo data generation codeunit (5691) via OData.
#>
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

<#
.SYNOPSIS
    Runs the legacy DemoTool (codeunit 101899) via ClientContext page action.
.DESCRIPTION
    Stages DemoTool resources into the container, then uses the web client to
    open page 101900 and invoke "Create Demo Data from Config".
#>
function Invoke-LegacyDemoDataTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-TestCompanyName),
        [PSCredential]$Credential,
        [string]$Tenant = "default",
        [ValidateSet("Standard","Evaluation","Extended")]
        [string]$DemoDataType = "Extended"
    )

    $ErrorActionPreference = "Stop"

    Write-Host "Initializing company"
    Invoke-NavContainerCodeunit -Codeunitid 2 -containerName $ContainerName -CompanyName $CompanyName

    $countryCode = Get-CountryCodeFromSettings

    Initialize-DemoToolResources -ContainerName $ContainerName -CountryCode $countryCode -DemoDataType $DemoDataType

    Invoke-DemoToolPageAction -ContainerName $ContainerName -CompanyName $CompanyName -Credential $Credential -Tenant $Tenant
}

<#
.SYNOPSIS
    Smoke-tests the legacy DemoTool for one or more non-Extended data types against a throwaway company.
.DESCRIPTION
    BCApps legacy tests only generate Extended demo data, so the Standard/Evaluation generation path
    ('Interface Trial Data'.CreateSetupData, CU122000) is never exercised in BCApps CI. Bugs on that path
    (e.g. a missing localization DemoTool override assigning a non-existent G/L account) therefore only
    surface later in the NAV translated-country build, which loops Standard/Evaluation/Extended.

    This function closes that gap: for each requested data type it creates a disposable company, runs the
    legacy DemoTool into it, and removes it again. It is designed to run BEFORE the real (Extended) test
    company is built. Because New-TestCompany subsequently deletes all companies and recreates the real one
    from a clean slate, this smoke test cannot interfere with the demo data the tests actually run against.

    The DemoTool bug class this targets throws DURING generation (before any rapidstart export), so a
    throwaway-company run reliably reproduces it without needing the full generate/export/delete pipeline.
.PARAMETER DemoDataTypes
    One or more of "Standard","Evaluation". Extended is skipped here because it is already covered by the
    real test-company generation.
#>
function Invoke-LegacyDemoDataSmokeTest() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [PSCredential]$Credential,
        [string]$Tenant = "default",
        [string[]]$DemoDataTypes = @("Standard")
    )

    $ErrorActionPreference = "Stop"

    foreach ($demoDataType in $DemoDataTypes) {
        if ($demoDataType -eq "Extended") {
            Write-Host "Skipping Extended in demo-data smoke test (already covered by the real test company)"
            continue
        }

        $smokeCompanyName = "Smoke $demoDataType"
        Write-Host "=== Legacy DemoTool smoke test: DataType=$demoDataType (throwaway company '$smokeCompanyName') ==="

        # Evaluation demo data requires an evaluation company; Standard uses a normal company.
        $isEvaluation = ($demoDataType -eq "Evaluation")

        try {
            Write-Host "Creating throwaway company '$smokeCompanyName' (evaluation=$isEvaluation)"
            New-CompanyInBcContainer -containerName $ContainerName -companyName $smokeCompanyName -evaluationCompany:$isEvaluation

            Invoke-LegacyDemoDataTool -ContainerName $ContainerName -CompanyName $smokeCompanyName `
                -Credential $Credential -Tenant $Tenant -DemoDataType $demoDataType

            Write-Host "Legacy DemoTool smoke test for DataType=$demoDataType succeeded"
        } catch {
            throw "Legacy DemoTool smoke test FAILED for DataType=$demoDataType (country $(Get-CountryCodeFromSettings)). This path is exercised by the NAV translated-country build but not by BCApps Extended-only demo data. Error: $($_.Exception.Message)"
        } finally {
            # Always remove the throwaway company so it never lingers into the real test run.
            if (Get-CompanyInBcContainer -containerName $ContainerName | Where-Object { $_.CompanyName -eq $smokeCompanyName }) {
                Write-Host "Removing throwaway company '$smokeCompanyName'"
                Remove-CompanyInBcContainer -containerName $ContainerName -companyName $smokeCompanyName
            }
        }
    }
}

<#
.SYNOPSIS
    Opens page 101900 via ClientContext and invokes the "Create Demo Data from Config" action.
.DESCRIPTION
    Connects to the container's web client, opens the Demonstration Data Tool page,
    copies resource files to all GUID session folders, then invokes the action.
#>
function Invoke-DemoToolPageAction() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [string]$CompanyName,
        [PSCredential]$Credential,
        [string]$Tenant = "default"
    )

    $ErrorActionPreference = "Stop"

    $clientContext = New-BcClientContext -ContainerName $ContainerName -CompanyName $CompanyName -Credential $Credential -Tenant $Tenant

    try {
        Write-Host "Opening page 101900 (Demonstration Data Tool)"
        $form = $clientContext.OpenForm(101900)
        if ($null -eq $form) {
            throw "Failed to open page 101900"
        }

        # Copy resources to ALL GUID user profile directories AFTER the page is open.
        # Opening the page establishes the session's GUID folder — copying now ensures
        # that folder has DemoDataConfig.xml when codeunit 101899 reads from TemporaryPath().
        Write-Host "Copying DemoTool resources to all GUID user profile folders"
        Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
            $guidDirs = @(Get-ChildItem "C:\ProgramData\Microsoft\Microsoft Dynamics NAV\*\Server\*\users" -Directory -Recurse -Depth 1 -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' })
            if (-not $guidDirs -or $guidDirs.Count -eq 0) {
                throw "No user profile GUID directories found"
            }
            foreach ($guidDir in $guidDirs) {
                Write-Host "Copying DemoTool resources to $($guidDir.FullName)"
                Copy-Item -Path "C:\DemoToolResources\*" -Destination $guidDir.FullName -Recurse -Force
            }
            Write-Host "Copied to $($guidDirs.Count) GUID folder(s)"
        }

        $actionName = "Create Demo Data from Config"
        Write-Host "Invoking action '$actionName'"
        $action = $clientContext.GetActionByName($form, $actionName)
        if ($null -eq $action) {
            throw "Action '$actionName' not found on page 101900"
        }

        # Start a transcript to capture ERROR DIALOG messages from the ClientContext event handler.
        # The event handler's throw runs in an event context and doesn't propagate to InvokeAction,
        # so we detect errors by scanning the transcript output afterwards.
        $transcriptPath = Join-Path $env:TEMP "DemoToolTranscript.txt"
        Start-Transcript -Path $transcriptPath -Force | Out-Null
        try {
            $clientContext.InvokeAction($action)
        } finally {
            Stop-Transcript | Out-Null
        }

        $transcript = Get-Content $transcriptPath -Raw
        if ($transcript -match "ERROR DIALOG:\s*(.+)") {
            throw "DemoTool failed: $($Matches[1])"
        }

        Write-Host "DemoTool action completed successfully"

        $clientContext.CloseForm($form)
    }
    finally {
        if ($null -ne $clientContext) {
            $clientContext.Dispose()
        }
    }
}

<#
.SYNOPSIS
    Sets up ClientContext DLLs and returns a connected ClientContext instance.
.DESCRIPTION
    Copies ClientContext scripts and DLLs from BcContainerHelper and the container,
    loads them, and creates a web client connection to the specified container.
#>
function New-BcClientContext() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [string]$CompanyName,
        [PSCredential]$Credential,
        [string]$Tenant = "default"
    )

    $ErrorActionPreference = "Stop"

    if (-not $Credential) {
        throw "No credential provided. The pipeline must pass credentials for the Client Context connection."
    }

    $customConfig = Get-BcContainerServerConfiguration -ContainerName $ContainerName
    $publicWebBaseUrl = "$($customConfig.PublicWebBaseUrl)".TrimEnd('/')
    if ([string]::IsNullOrEmpty($publicWebBaseUrl)) {
        throw "Container $ContainerName has no PublicWebBaseUrl configured. WebClient is required."
    }

    $clientServicesCredentialType = $customConfig.ClientServicesCredentialType

    $serviceUrl = "$publicWebBaseUrl/cs?tenant=$([Uri]::EscapeDataString($Tenant))"
    if (-not [string]::IsNullOrEmpty($CompanyName)) {
        $serviceUrl += "&company=$([Uri]::EscapeDataString($CompanyName))"
    }

    $tempRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
    $PsTestToolFolder = Join-Path $tempRoot "PsTestTool-$ContainerName"
    if (-not (Test-Path $PsTestToolFolder)) {
        New-Item -Path $PsTestToolFolder -ItemType Directory -Force | Out-Null
    }

    $bcHelperModulePath = (Get-Module BcContainerHelper).ModuleBase
    Copy-Item -Path (Join-Path $bcHelperModulePath "AppHandling\ClientContext.ps1") -Destination $PsTestToolFolder -Force
    Copy-Item -Path (Join-Path $bcHelperModulePath "AppHandling\PsTestFunctions.ps1") -Destination $PsTestToolFolder -Force

    $clientDllPath = Join-Path $PsTestToolFolder "Microsoft.Dynamics.Framework.UI.Client.dll"
    $newtonSoftDllPath = Join-Path $PsTestToolFolder "Newtonsoft.Json.dll"

    if (-not ((Test-Path $clientDllPath) -and (Test-Path $newtonSoftDllPath))) {
        $containerDllPaths = Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
            $nstFolder = "C:\Program Files\Microsoft Dynamics NAV\*\Service"
            $newtonSoftDllPath = (Get-Item "$nstFolder\Management\Newtonsoft.Json.dll" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
            if (-not $newtonSoftDllPath) { $newtonSoftDllPath = (Get-Item "$nstFolder\Newtonsoft.Json.dll" | Select-Object -First 1).FullName }

            $testAssemblies = "C:\Test Assemblies"
            $paths = [ordered]@{
                'Newtonsoft.Json.dll'                       = $newtonSoftDllPath
                'Microsoft.Dynamics.Framework.UI.Client.dll' = Join-Path $testAssemblies 'Microsoft.Dynamics.Framework.UI.Client.dll'
            }
            foreach ($dll in @('Microsoft.Internal.AntiSSRF.dll', 'System.Threading.Tasks.Extensions.dll')) {
                $srcDll = Join-Path $testAssemblies $dll
                if (Test-Path $srcDll) { $paths[$dll] = $srcDll }
            }
            $paths
        }

        foreach ($entry in $containerDllPaths.GetEnumerator()) {
            Copy-FileFromBcContainer -containerName $ContainerName -containerPath $entry.Value -localPath (Join-Path $PsTestToolFolder $entry.Key)
        }
        Write-Host "Client DLLs copied"
    } else {
        Write-Host "Client DLLs already present in $PsTestToolFolder"
    }

    # Load Client Context via PsTestFunctions.ps1 (handles Add-Type DLL loading)
    . (Join-Path $PsTestToolFolder "PsTestFunctions.ps1") -newtonSoftDllPath $newtonSoftDllPath -clientDllPath $clientDllPath -clientContextScriptPath (Join-Path $PsTestToolFolder "ClientContext.ps1")

    Write-Host "Connecting to $serviceUrl"
    return New-ClientContext -serviceUrl $serviceUrl -auth $clientServicesCredentialType -credential $credential -interactionTimeout ([timespan]::FromHours(2)) -culture "en-US"
}

<#
.SYNOPSIS
    Returns the country code from the AL-Go project settings. Defaults to "W1".
#>
function Get-CountryCodeFromSettings() {
    $country = Get-ALGoSetting -Key "country"
    if ($country) {
        return $country.ToUpper()
    }
    return "W1"
}

<#
.SYNOPSIS
    Stages DemoTool resource files (Pictures, O365, DemoDataConfig.xml) into the container.
.DESCRIPTION
    Merges resources from W1 base, optional region (DACH/NA/APAC), and country layers,
    then copies them to C:\DemoToolResources inside the container.
#>
function Initialize-DemoToolResources() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [string]$CountryCode = "W1",
        [string]$DemoDataType = "Extended"
    )

    $ErrorActionPreference = "Stop"
    $repoRoot = Get-BaseFolder

    # Build layer chain: W1 -> region -> country (later layers overwrite earlier)
    $regionMap = @{ AT='DACH'; DE='DACH'; CH='DACH'; CA='NA'; MX='NA'; US='NA'; AU='APAC'; NZ='APAC' }
    $layers = @("W1")
    if ($regionMap.ContainsKey($CountryCode)) { $layers += $regionMap[$CountryCode] }
    if ($CountryCode -ne "W1") { $layers += $CountryCode }

    Write-Host "DemoTool resource layers: $($layers -join ' -> ')"

    # Stage all resources locally, layered (later layers overwrite earlier)
    $stagingPath = Join-Path $env:TEMP "DemoToolResources"
    if (Test-Path $stagingPath) { Remove-Item $stagingPath -Recurse -Force }
    New-Item -Path $stagingPath -ItemType Directory -Force | Out-Null

    foreach ($layer in $layers) {
        if ($layer -eq "W1") {
            $picturesPath = Join-Path $repoRoot "src\DemoTool\Pictures"
            $o365Path = Join-Path $repoRoot "src\DemoTool\O365"
        } else {
            $picturesPath = Join-Path $repoRoot "src\GDL\$layer\App\DemoTool\Pictures"
            $o365Path = $null
        }

        if ($picturesPath -and (Test-Path $picturesPath)) {
            Write-Host "Staging Pictures from $layer layer"
            Copy-Item -Path "$picturesPath\*" -Destination $stagingPath -Recurse -Force
        }
        if ($o365Path -and (Test-Path $o365Path)) {
            Write-Host "Staging O365 from $layer layer"
            Copy-Item -Path $o365Path -Destination $stagingPath -Recurse -Force
        }
    }

    # Find the most specific DemoDataConfig.xml (country > region > W1) and stage it
    $configSource = $null
    for ($i = $layers.Count - 1; $i -ge 0; $i--) {
        if ($layers[$i] -eq "W1") {
            $candidatePath = Join-Path $repoRoot "src\DemoTool\DemoDataConfig.xml"
        } else {
            $candidatePath = Join-Path $repoRoot "src\GDL\$($layers[$i])\DevBase\DemoTool\DemoDataConfig.xml"
        }
        if (Test-Path $candidatePath) {
            $configSource = $candidatePath
            break
        }
    }
    if (-not $configSource) {
        throw "DemoDataConfig.xml not found in any layer: $($layers -join ', ')"
    }
    Write-Host "Using DemoDataConfig.xml from: $configSource"

    $configXml = [xml](Get-Content $configSource)
    $configXml.DemoDataSetup.DataType = $DemoDataType

    # en-IN (16393) is not available in the container's Windows Language table because
    # Server Core doesn't have the en-IN language pack. Use en-US (1033) instead.
    $dataLanguageId = $configXml.DemoDataSetup.DataLanguageID
    if ($dataLanguageId -eq "16393") {
        Write-Host "Replacing DataLanguageID 16393 (en-IN) with 1033 (en-US) for container compatibility"
        $configXml.DemoDataSetup.DataLanguageID = "1033"
    }

    $configXml.Save((Join-Path $stagingPath "DemoDataConfig.xml"))

    # Copy staged resources into the container at a staging path
    Write-Host "Copying DemoTool resources to container"
    Copy-ItemToBcContainer -containerName $ContainerName -localPath $stagingPath -containerPath "C:\DemoToolResources"
    Remove-Item $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Installs all published apps in the container on the default tenant.
#>
function Install-AllApps() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    # Install all published-but-not-installed apps in dependency order
    Write-Host "Installing all published apps..."
    $publishedApps = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst
    $uninstalledApps = $publishedApps | Where-Object { $_.IsPublished -and -not $_.IsInstalled }

    if ($uninstalledApps.Count -eq 0) {
        Write-Host "All apps already installed"
        return
    }

    Write-Host "Installing $($uninstalledApps.Count) apps"
    foreach ($app in $uninstalledApps) {
        Write-Host "Installing $($app.Name) ($($app.Version))"
        Install-BcContainerApp -containerName $ContainerName -appName $app.Name -appVersion $app.Version
    }
    Write-Host "All apps installed"
}

<#
.SYNOPSIS
    Installs only the base app groups (Base, TestFramework, LocalBaseExtensions) needed before running DemoTool.
.DESCRIPTION
    Uses Get-ApplicationGroup from ALAppBuild.psm1 to determine which apps belong to the
    base groups, then installs only those. Remaining apps are installed after DemoTool runs.
#>
function Install-BaseAppsForDemoTool() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [string]$CountryCode = "W1"
    )

    # Install only the apps needed before DemoTool runs.
    # This matches the internal build's BuildTestDatabase.ps1 which installs
    # Base, TestFramework, LocalBaseExtensions groups + DemoTool before running the DemoTool.
    $repoRoot = Get-BaseFolder
    $env:INETROOT = $repoRoot

    if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
        function global:Write-Log {
            param([Parameter(Position = 0)][string]$Message, [string]$ForegroundColor)
            Write-Host $Message
        }
    }
    Import-Module (Join-Path $repoRoot "build\scripts\ALAppBuild.psm1") -Force

    $baseAppNames = @()
    foreach ($groupName in @('Base', 'TestFramework', 'LocalBaseExtensions')) {
        $apps = Get-ApplicationGroup -GroupName $groupName -CountryCode $CountryCode -SkipLanguagePacks
        $baseAppNames += $apps | ForEach-Object { $_.ApplicationName }
    }
    $baseAppNames += 'DemoTool'
    $baseAppNames = $baseAppNames | Sort-Object -Unique
    Write-Host "Base apps for DemoTool: $($baseAppNames.Count) apps"

    # Install only those apps (in dependency order)
    $publishedApps = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst
    $appsToInstall = $publishedApps | Where-Object { $_.IsPublished -and -not $_.IsInstalled -and ($baseAppNames -contains $_.Name) }

    Write-Host "Installing $($appsToInstall.Count) base apps"
    foreach ($app in $appsToInstall) {
        Write-Host "Installing $($app.Name) ($($app.Version))"
        Install-BcContainerApp -containerName $ContainerName -appName $app.Name -appVersion $app.Version
    }
    Write-Host "Base apps installed"
}

<#
.SYNOPSIS
    Returns the test company name from AL-Go settings, defaulting to "CRONUS International Ltd.".
#>
function Get-TestCompanyName() {
    $companyName = Get-ALGoSetting -Key "companyName"
    if ([string]::IsNullOrEmpty($companyName)) {
        return "CRONUS International Ltd." # Fallback in case no company name is specified in settings
    } else {
        return $companyName
    }
}

<#
.SYNOPSIS
    Orchestrates demo data generation based on the test type.
.DESCRIPTION
    For Legacy tests: installs base apps, creates test company, runs DemoTool, then installs remaining apps.
    For other test types: installs all apps and runs Contoso demo data tool.
#>
function Invoke-DemoDataGeneration
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [ValidateSet("UnitTest","IntegrationTest","Uncategorized","Legacy")]
        [string]$TestType,
        [PSCredential]$Credential,
        [string]$Tenant = "default"
    )
    if ($TestType -eq "UnitTest") {
        Install-AllApps -ContainerName $ContainerName
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "UnitTest shouldn't have dependency on any Demo Data, skipping demo data generation"
        return
    } elseif( $TestType -eq "IntegrationTest" ) {
        Install-AllApps -ContainerName $ContainerName
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "Proceeding with demo data generation (SetupData) as test type is set to IntegrationTest"
        Invoke-ContosoDemoToolWithRetry -ContainerName $ContainerName -CompanyName (Get-TestCompanyName) -SetupData
    } elseif( $TestType -eq "Uncategorized" ) {
        Install-AllApps -ContainerName $ContainerName
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName) -EvaluationCompany
        Write-Host "Proceeding with full demo data generation as test type is set to Uncategorized"
        Invoke-ContosoDemoToolWithRetry -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
    } elseif ( $TestType -eq "Legacy" ) {
        Install-BaseAppsForDemoTool -ContainerName $ContainerName -CountryCode (Get-CountryCodeFromSettings)

        # Optional: smoke-test non-Extended demo data (Standard/Evaluation) against throwaway companies
        # BEFORE building the real Extended test company. This catches DemoTool bugs on the
        # 'Interface Trial Data'.CreateSetupData path that otherwise only fail in the NAV translated-country
        # build. Gated by the "smokeTestDemoDataTypes" AL-Go setting (array, e.g. ["Standard"]); when unset
        # or empty, behavior is unchanged. Runs before New-TestCompany, which wipes all companies and
        # recreates the real one, guaranteeing the smoke run cannot affect the demo data tests run against.
        $smokeTestDemoDataTypes = Get-ALGoSetting -Key "smokeTestDemoDataTypes"
        if ($smokeTestDemoDataTypes -and $smokeTestDemoDataTypes.Count -gt 0) {
            Invoke-LegacyDemoDataSmokeTest -ContainerName $ContainerName -Credential $Credential -Tenant $Tenant -DemoDataTypes $smokeTestDemoDataTypes
        }

        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "Proceeding with full demo data generation as test type is set to Legacy"
        Invoke-LegacyDemoDataTool -ContainerName $ContainerName -Credential $Credential -Tenant $Tenant
        Install-AllApps -ContainerName $ContainerName
    }
    else {
        throw "Unknown test type $TestType."
    }

}

<#
.SYNOPSIS
    Creates a new company in the container for testing.
#>
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
    Invoke-DemoDataGeneration -ContainerName $parameters.ContainerName -TestType (Get-ALGoSetting -Key "testType") -Credential $parameters.credential -Tenant $parameters.tenant
} catch {
    Write-Host "An error occurred during demo data generation: $($_.Exception.Message)"
    throw
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