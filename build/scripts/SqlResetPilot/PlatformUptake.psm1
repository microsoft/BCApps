function Get-SqlPlatformUptake {
    Get-Content (Join-Path $PSScriptRoot 'PlatformUptake.json') -Raw | ConvertFrom-Json
}

function Assert-SqlPlatformUptakeContext {
    param([switch]$Cell)
    if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or
        $env:GITHUB_REF -ne 'refs/heads/features/653457-sql-platform-fix-uptake' -or
        $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch' -or $env:GITHUB_RUN_ATTEMPT -ne '1' -or
        $env:BC_SQL_UPTAKE_AUTHORIZATION -ne 'AB653457-fixed-platform-original-control-10' -or
        $env:GITHUB_RUN_ID -notmatch '^\d{1,20}$' -or $env:GITHUB_SHA -notmatch '^[0-9a-f]{40}$') {
        throw 'Fixed-platform uptake requires its exact authorized manual branch and attempt one.'
    }
    if ($Cell -and ($env:BC_SQL_PILOT_ARM -ne 'control' -or $env:BC_SQL_API_EXPERIMENT -ne 'control' -or
        $env:BC_SQL_PILOT_COUNTRY -notin @('W1', 'DE') -or $env:BC_SQL_PILOT_TRIAL -notmatch '^[1-5]$')) {
        throw 'Fixed-platform uptake permits only the ten original control cells.'
    }
}

function Get-SqlPlatformUptakeCell {
    foreach ($trial in 1..5) {
        foreach ($country in @('W1', 'DE')) {
            [PSCustomObject]@{ experiment = 'control'; country = $country; trial = $trial }
        }
    }
}

function Save-SqlPlatformUptakeSnapshot {
    param([ValidateSet('W1', 'DE')][string]$Country, [string]$Directory)
    $pin = Get-SqlPlatformUptake
    $snapshot = @($pin.snapshots | Where-Object country -eq $Country)[0]
    if (-not $env:GH_TOKEN) { throw 'Actions credential is required for immutable package transport.' }
    $metadata = Invoke-RestMethod "https://api.github.com/repos/microsoft/BCApps/actions/artifacts/$($snapshot.id)" `
        -Headers @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
    if ($metadata.id -ne $snapshot.id -or $metadata.digest -ne "sha256:$($snapshot.digest)") {
        throw 'Original comparison snapshot ID/digest differs from the canonical uptake manifest.'
    }
    Import-Module (Join-Path $PSScriptRoot 'Comparison.psm1') -Force
    Save-SqlComparisonSnapshot -ArtifactId $snapshot.id -RunId $pin.originalSnapshotRun `
        -HeadSha $pin.comparisonBase -Country $Country -Directory $Directory
}

function Assert-SqlPlatformUptakePackageSet {
    param([ValidateSet('W1', 'DE')][string]$Country, [string]$Kind, [array]$Files)
    $pin = @((Get-SqlPlatformUptake).applicationArtifacts | Where-Object { $_.country -eq $Country -and $_.kind -eq $Kind })
    $canonical = @($Files | Sort-Object name | ForEach-Object { "$($_.name)=$($_.sha256.ToLowerInvariant())" }) -join "`n"
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $digest = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical)))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    if ($pin.Count -ne 1 -or $Files.Count -ne $pin[0].compiledPackageCount -or
        $digest -ne $pin[0].compiledPackageSetSha256) {
        throw 'Extracted compiled packages differ from the original control package set.'
    }
}

Export-ModuleMember -Function Get-SqlPlatformUptake, Assert-SqlPlatformUptakeContext,
    Get-SqlPlatformUptakeCell, Save-SqlPlatformUptakeSnapshot, Assert-SqlPlatformUptakePackageSet
