param([string]$RegistryId, [string]$RegistryDigest)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Reuse.psm1')
$context = Get-ExpandedContext
$policy = Get-ExpandedReusePolicy
$source = Get-Content (Join-Path $context.output 'source-receipt.json') -Raw | ConvertFrom-Json
$registryDirectory = Join-Path $env:GITHUB_WORKSPACE 'expanded-registry-download'
$registry = Get-ExpandedReuseRegistry -Id $RegistryId -Digest $RegistryDigest -Directory $registryDirectory -Source $source
$entries = @($registry.countries | Where-Object country -CEQ $context.cell.country)
if ($entries.Count -ne 1) { throw 'Country registry missing or duplicate.' }
$entry = $entries[0]
$countryDirectory = Join-Path $env:GITHUB_WORKSPACE 'expanded-country-manifest'
$null = Save-ExpandedArtifact -Id $entry.artifactId -Digest $entry.sha256 -Directory $countryDirectory `
    -ExpectedRunId $policy.runId -ExpectedHead $policy.sourceHead
Assert-ExpandedReuseCountry -Entry $entry -Directory $countryDirectory
$manifest = Get-Content (Join-Path $countryDirectory 'packages.json') -Raw | ConvertFrom-Json
$packageRoot = Join-Path $env:GITHUB_WORKSPACE 'expanded-packages'
$null = New-Item -ItemType Directory -Path $packageRoot
foreach ($artifact in $manifest.artifacts) {
    $directory = Join-Path $env:GITHUB_WORKSPACE "expanded-archive-$($artifact.kind)"
    $null = Save-ExpandedArtifact -Id $artifact.id -Digest $artifact.sha256 -Directory $directory `
        -ExpectedRunId $policy.runId -ExpectedHead $policy.sourceHead
    $kindRoot = Join-Path $packageRoot $artifact.kind
    $null = New-Item -ItemType Directory -Path $kindRoot
    foreach ($file in Get-ChildItem $directory -Recurse -File) {
        if ($file.Extension -cne '.app') { throw 'Unexpected file in package archive.' }
        if (Test-Path (Join-Path $kindRoot $file.Name)) { throw 'Duplicate package file in archive.' }
        Copy-Item $file.FullName (Join-Path $kindRoot $file.Name) -ErrorAction Stop
    }
}
Assert-ExpandedApiPackageManifest -Manifest $manifest -Country $context.cell.country -RunId $policy.runId `
    -SourceHead $policy.sourceHead -SourceTree $source.sourceTree -PackageDirectory $packageRoot
foreach ($kind in @('Apps', 'TestApps')) {
    $paths = @(Get-ChildItem (Join-Path $packageRoot $kind) -File | ForEach-Object FullName)
    $list = Join-Path $context.output "$kind.json"
    ConvertTo-Json -InputObject $paths | Set-Content $list
    "$kind=$list" | Add-Content $env:GITHUB_OUTPUT
}
Copy-Item (Join-Path $countryDirectory 'packages.json') (Join-Path $context.output 'packages.json')
@{ registryId = $RegistryId; registrySha256 = $RegistryDigest; countryManifestId = $entry.artifactId
    countryManifestSha256 = $entry.sha256; artifacts = $manifest.artifacts
    adoption = (New-ExpandedAdoptionReceipt -Source $source)
    transportVerified = $true; packageFilesVerified = $true } |
    ConvertTo-Json -Depth 20 | Set-Content (Join-Path $context.output 'transport-proof.json')
