Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')

function Get-ExpandedReusePolicy {
    <#.SYNOPSIS
    Returns the single reviewed producer identity and immutable registry pins.
    #>
    @{
        runId = '37896636913'; sourceHead = 'bd763f0b489277dc3696bb352396456d625ab63c'; attempt = 1
        sourceTree = '6605c0616ac6578d561435d0f03a7ebfb19e36d9'
        overlaySha256 = 'aec92cd14f5b9a6ca9b3504e6fd9c3ab48926ddee6a95c48596b40101430ae37'
        registryId = '11613371849'
        registryDigest = 'f42092163c96cbeb2187547125030cbd39d0a12d2ad5d93a5f5f241645f7617e'
        registryFileSha256 = '2dbb7aef561c583323b895d02704d88f2e2909b2ada58a88c153234b80148828'
        countries = @{
            W1 = @{ id = '11604275431'; sha256 = 'c0847a1071243750c8abb29c268b22a7f0c78dbcfe45be9eb868f031c830c439' }
            DE = @{ id = '11604341329'; sha256 = 'd0b61f91416ff614864e9bca36f2e112ba8427f226efc07c9289eaa7681bd8d7' }
            CA = @{ id = '11609651143'; sha256 = '797a5d32f1d5f4640c9e9ad2842f14830a5e670fc26426d4919426a70aff763f' }
            US = @{ id = '11608823958'; sha256 = 'b463811d7b1aa0e1aba3559c287d5ccacf1bc09d5203f962f92676fb8b59b59f' }
            IT = @{ id = '11613585211'; sha256 = 'a79638727e4a281e857a14683b0d9c52ab1aea0d3fefa463e4de5df32e728a64' }
        }
    }
}

function Assert-ExpandedProducerRun {
    <#.SYNOPSIS
    Requires the approved producer to remain terminal on its original attempt.
    #>
    $policy = Get-ExpandedReusePolicy
    $run = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/BCApps/actions/runs/$($policy.runId)" `
        -Headers @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
    if ([string]$run.id -cne $policy.runId -or $run.head_sha -cne $policy.sourceHead -or
        $run.run_attempt -ne $policy.attempt -or $run.status -cne 'completed' -or $run.conclusion -cne 'failure' -or
        $run.repository.full_name -cne 'microsoft/BCApps') { throw 'Approved producer run identity, terminal state or original attempt changed.' }
}

function Assert-ExpandedReuseSource {
    <#.SYNOPSIS
    Separates current consumer identity from identical staged producer AL source.
    #>
    param([Parameter(Mandatory)]$Source)
    Assert-ExpandedApiDispatch
    $policy = Get-ExpandedReusePolicy
    if ($Source.runId -cne $env:GITHUB_RUN_ID -or $Source.sourceHead -cne $env:GITHUB_SHA -or
        $env:GITHUB_RUN_ID -ceq $policy.runId -or $env:GITHUB_SHA -ceq $policy.sourceHead -or
        $env:GITHUB_SHA -notmatch '^[a-f0-9]{40}$' -or $Source.attempt -ne 1 -or
        $Source.compiled -isnot [bool] -or $Source.compiled -or
        $Source.sourceTree -cne $policy.sourceTree -or $Source.overlaySha256 -cne $policy.overlaySha256) {
        throw 'Consumer identity or staged source/overlay differs from the approved producer.'
    }
}

function Assert-ExpandedReuseRegistry {
    <#.SYNOPSIS
    Checks all five original country manifests against the adoption policy.
    #>
    param([Parameter(Mandatory)]$Registry, [Parameter(Mandatory)]$Source)
    Assert-ExpandedReuseSource -Source $Source
    $policy = Get-ExpandedReusePolicy
    if ($Registry.runId -cne $policy.runId -or $Registry.sourceHead -cne $policy.sourceHead -or
        @($Registry.countries).Count -ne 5 -or
        (@($Registry.countries.country | Sort-Object -Unique) -join ',') -cne 'CA,DE,IT,US,W1') { throw 'Wrong approved producer registry.' }
    $pins = Get-ExpandedApiPinSet
    foreach ($entry in $Registry.countries) {
        $expected = $policy.countries[$entry.country]
        $manifest = $entry.packageManifest
        if ([string]$entry.artifactId -cne $expected.id -or $entry.sha256 -cne $expected.sha256 -or
            $manifest.country -cne $entry.country -or $manifest.runId -cne $policy.runId -or
            $manifest.sourceHead -cne $policy.sourceHead -or $manifest.attempt -ne $policy.attempt -or
            $manifest.sourceTree -cne $Source.sourceTree -or $manifest.overlaySha256 -cne $Source.overlaySha256 -or
            $manifest.freshCompilation -isnot [bool] -or -not $manifest.freshCompilation) { throw 'Producer manifest or source provenance drift.' }
        foreach ($key in $pins.Keys) {
            if ($manifest.pins.$key -cne $pins[$key]) { throw "Reused package $key pin drift." }
        }
    }
}

function Get-ExpandedReuseRegistry {
    <#.SYNOPSIS
    Verifies producer transport and registry bytes without rewriting provenance.
    #>
    param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Digest,
        [Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)]$Source)
    Assert-ExpandedReuseSource -Source $Source
    $policy = Get-ExpandedReusePolicy
    if ($Id -cne $policy.registryId -or $Digest -cne $policy.registryDigest) { throw 'Only the reviewed registry ID and digest may be adopted.' }
    Assert-ExpandedProducerRun
    $null = Save-ExpandedArtifact -Id $Id -Digest $Digest -Directory $Directory `
        -ExpectedRunId $policy.runId -ExpectedHead $policy.sourceHead
    $path = Join-Path $Directory 'registry.json'
    if ((Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -cne $policy.registryFileSha256) { throw 'Approved registry file hash mismatch.' }
    $registry = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-ExpandedReuseRegistry -Registry $registry -Source $Source
    $registry
}

function Assert-ExpandedReuseCountry {
    <#.SYNOPSIS
    Checks immutable country manifest equality and owned compiler cleanup.
    #>
    param([Parameter(Mandatory)]$Entry, [Parameter(Mandatory)][string]$Directory)
    $manifest = Get-Content (Join-Path $Directory 'packages.json') -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
    $cleanup = Get-Content (Join-Path $Directory 'compiler-cleanup.json') -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
    if (($manifest | ConvertTo-Json -Depth 40 -Compress) -cne ($Entry.packageManifest | ConvertTo-Json -Depth 40 -Compress)) {
        throw 'Country package manifest changed after producer sealing.'
    }
    if ($cleanup.compilerRemaining -ne $false -or $cleanup.absenceVerified -ne $true -or
        $cleanup.ownershipValidated -ne $true -or $cleanup.failureType) { throw 'Producer compiler cleanup proof missing.' }
}

function New-ExpandedAdoptionReceipt {
    <#.SYNOPSIS
    Creates a separate consumer receipt; never rewrites producer manifests.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Returns an in-memory receipt; no state change.')]
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Source)
    Assert-ExpandedReuseSource -Source $Source
    $policy = Get-ExpandedReusePolicy
    @{
        mode = 'sealed-producer-reuse'; compiledThisRun = $false
        producer = @{ runId = $policy.runId; sourceHead = $policy.sourceHead; attempt = $policy.attempt }
        consumer = @{ runId = $Source.runId; sourceHead = $Source.sourceHead; attempt = $Source.attempt }
        sourceTree = $Source.sourceTree; overlaySha256 = $Source.overlaySha256
        registryId = $policy.registryId; registryDigest = $policy.registryDigest
        registryFileSha256 = $policy.registryFileSha256
        priorSetupInvalidRun = $policy.runId
    }
}

function Assert-ExpandedAdoptionReceipt {
    <#.SYNOPSIS
    Prevents a producer or old consumer run from being claimed as current runtime evidence.
    #>
    param([Parameter(Mandatory)]$Receipt)
    $source = @{ runId = $env:GITHUB_RUN_ID; sourceHead = $env:GITHUB_SHA; attempt = 1; compiled = $false
        sourceTree = $Receipt.sourceTree; overlaySha256 = $Receipt.overlaySha256 }
    $expected = New-ExpandedAdoptionReceipt -Source $source
    foreach ($key in @('mode', 'sourceTree', 'overlaySha256', 'registryId', 'registryDigest', 'registryFileSha256', 'priorSetupInvalidRun')) {
        if ([string]$Receipt.$key -cne [string]$expected[$key]) { throw "Adoption $key mismatch." }
    }
    if ($Receipt.compiledThisRun -isnot [bool] -or $Receipt.compiledThisRun) { throw 'Reused packages must not be claimed as consumer compilation.' }
    foreach ($role in @('producer', 'consumer')) {
        foreach ($key in @('runId', 'sourceHead', 'attempt')) {
            if ([string]$Receipt.$role.$key -cne [string]$expected[$role][$key]) { throw "Adoption $role/$key mismatch." }
        }
    }
}

Export-ModuleMember -Function Get-ExpandedReusePolicy, Assert-ExpandedProducerRun, Assert-ExpandedReuseSource,
    Assert-ExpandedReuseRegistry, Get-ExpandedReuseRegistry, Assert-ExpandedReuseCountry,
    New-ExpandedAdoptionReceipt, Assert-ExpandedAdoptionReceipt
