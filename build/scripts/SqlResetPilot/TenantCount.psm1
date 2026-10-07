function Test-SqlTenantExperiment {
    $env:GITHUB_REPOSITORY -eq 'microsoft/BCApps' -and
    $env:GITHUB_REF -eq 'refs/heads/features/646383-sql-api-tenant-count-comparison' -and
    $env:GITHUB_EVENT_NAME -eq 'workflow_dispatch' -and $env:GITHUB_RUN_ATTEMPT -eq '1' -and
    $env:BC_SQL_PILOT_ARM -eq 'control' -and $env:BC_SQL_API_EXPERIMENT -eq 'control' -and
    $env:BC_SQL_TENANT_COUNT -in @('1', '2') -and $env:BC_SQL_PILOT_COUNTRY -in @('W1', 'DE') -and
    $env:BC_SQL_PILOT_TRIAL -match '^[1-5]$' -and $env:GITHUB_RUN_ID -match '^\d{1,20}$'
}

function Get-SqlTenantCell {
    foreach ($trial in 1..5) {
        $countries = if ($trial % 2) { @('W1', 'DE') } else { @('DE', 'W1') }
        $counts = if ($trial % 2) { @(1, 2) } else { @(2, 1) }
        foreach ($country in $countries) {
            foreach ($count in $counts) {
                [PSCustomObject]@{ tenantCount = $count; country = $country; trial = $trial }
            }
        }
    }
}

function Get-SqlTenantContainerName {
    if (-not (Test-SqlTenantExperiment)) { throw 'Invalid tenant-count diagnostic identity.' }
    "bcbuildprojectsTestApps$($env:BC_SQL_PILOT_COUNTRY)Trial$($env:BC_SQL_PILOT_TRIAL)t$($env:BC_SQL_TENANT_COUNT)$($env:GITHUB_RUN_ID)"
}

function Assert-SqlTenantContainer {
    param([string]$ContainerName)
    if ($ContainerName -ne (Get-SqlTenantContainerName)) { throw 'Unowned tenant-count container.' }
    if ((Get-BcContainerServerConfiguration -ContainerName $ContainerName).Multitenant -ne 'true') {
        throw 'One mounted tenant still requires a multitenant NST with a separate application database.'
    }
    $tenants = @(Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -scriptblock {
        @(Get-NAVTenant -ServerInstance $ServerInstance | ForEach-Object {
            @{ id = [string]$_.Id; database = [string]$_.DatabaseName; server = [string]$_.DatabaseServer; state = [string]$_.State }
        })
    })
    $expected = if ($env:BC_SQL_TENANT_COUNT -eq '1') { @('default') } else { @('default', 'tenant2') }
    if ($tenants.Count -ne $expected.Count -or
        @($tenants | Where-Object { $_.id -notin $expected -or $_.database -ne $_.id -or $_.state -ne 'Operational' }).Count -gt 0 -or
        @($tenants.id | Sort-Object -Unique).Count -ne $expected.Count) {
        throw 'Actual mounted tenants differ from the exact requested healthy worker set.'
    }
    @{
        utc = [DateTime]::UtcNow.ToString('o'); multitenant = $true
        requestedMountedTenants = [int]$env:BC_SQL_TENANT_COUNT; actualMountedTenants = $tenants.Count
        actualWorkers = $expected; workerCount = $expected.Count; reservedMountedSource = $false
        discoveryTenant = 'default'; templateDatabase = 'default-test-template'; tenants = $tenants
    } | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $env:BC_SQL_PILOT_OUTPUT 'mounted-tenants.json')
}

function Write-SqlTenantTiming {
    param([string]$Phase, [long]$StartedTicks, [string]$StartedUtc, [bool]$Completed)
    @{
        phase = $Phase; startedUtc = $StartedUtc; completedUtc = [DateTime]::UtcNow.ToString('o')
        startedTicks = $StartedTicks; frequency = [Diagnostics.Stopwatch]::Frequency
        elapsedMilliseconds = ([Diagnostics.Stopwatch]::GetTimestamp() - $StartedTicks) * 1000.0 / [Diagnostics.Stopwatch]::Frequency
        completed = $Completed
    } | ConvertTo-Json -Compress | Add-Content (Join-Path $env:BC_SQL_PILOT_OUTPUT 'phase-timing.jsonl')
}

Export-ModuleMember -Function Test-SqlTenantExperiment, Get-SqlTenantCell, Get-SqlTenantContainerName,
    Assert-SqlTenantContainer, Write-SqlTenantTiming
