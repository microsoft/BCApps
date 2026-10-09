$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Reuse.psm1')
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')
$policy = Get-ExpandedReusePolicy
$output = Join-Path $env:GITHUB_WORKSPACE 'expanded-adoption'
if (Test-Path $output) { throw 'Adoption output already exists.' }
$null = New-Item -ItemType Directory -Path $output
& (Join-Path $PSScriptRoot 'StageSource.ps1') | Set-Content (Join-Path $output 'source-receipt.json') -Encoding UTF8
$source = Get-Content (Join-Path $output 'source-receipt.json') -Raw | ConvertFrom-Json
$registry = Get-ExpandedReuseRegistry -Id $policy.registryId -Digest $policy.registryDigest `
    -Directory (Join-Path $output 'registry') -Source $source
foreach ($entry in $registry.countries) {
    $directory = Join-Path $output $entry.country
    $null = Save-ExpandedArtifact -Id $entry.artifactId -Digest $entry.sha256 -Directory $directory `
        -ExpectedRunId $policy.runId -ExpectedHead $policy.sourceHead
    Assert-ExpandedReuseCountry -Entry $entry -Directory $directory
    foreach ($artifact in $entry.packageManifest.artifacts) {
        $metadata = Get-ExpandedArtifact -Id $artifact.id -ExpectedRunId $policy.runId -ExpectedHead $policy.sourceHead
        if ($metadata.digest -cne "sha256:$($artifact.sha256)") { throw 'Producer package archive digest drift.' }
    }
}
New-ExpandedAdoptionReceipt -Source $source | ConvertTo-Json -Depth 20 |
    Set-Content (Join-Path $output 'adoption.json') -Encoding UTF8
"id=$($policy.registryId)" | Add-Content $env:GITHUB_OUTPUT
"digest=$($policy.registryDigest)" | Add-Content $env:GITHUB_OUTPUT
