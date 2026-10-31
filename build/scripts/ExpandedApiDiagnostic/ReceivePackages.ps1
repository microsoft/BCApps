param([string]$RegistryId, [string]$RegistryDigest)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
$context = Get-ExpandedContext
$registryDirectory = Join-Path $env:GITHUB_WORKSPACE 'expanded-registry-download'
$null = Save-ExpandedArtifact -Id $RegistryId -Digest $RegistryDigest -Directory $registryDirectory
$registry = Get-Content (Join-Path $registryDirectory 'registry.json') -Raw | ConvertFrom-Json
if ($registry.runId -cne $env:GITHUB_RUN_ID -or $registry.sourceHead -cne $env:GITHUB_SHA) { throw 'Wrong shared registry.' }
$entries = @($registry.countries | Where-Object country -CEQ $context.cell.country)
if ($entries.Count -ne 1) { throw 'Country registry missing or duplicate.' }
$entry = $entries[0]
$countryDirectory = Join-Path $env:GITHUB_WORKSPACE 'expanded-country-manifest'
$null = Save-ExpandedArtifact -Id $entry.artifactId -Digest $entry.sha256 -Directory $countryDirectory
$manifest = Get-Content (Join-Path $countryDirectory 'packages.json') -Raw | ConvertFrom-Json
if (($manifest | ConvertTo-Json -Depth 30 -Compress) -cne
    ($entry.packageManifest | ConvertTo-Json -Depth 30 -Compress)) { throw 'Country package manifest changed after sealing.' }
$packageRoot = Join-Path $env:GITHUB_WORKSPACE 'expanded-packages'
$null = New-Item -ItemType Directory -Path $packageRoot
foreach ($artifact in $manifest.artifacts) {
    $directory = Join-Path $env:GITHUB_WORKSPACE "expanded-archive-$($artifact.kind)"
    $null = Save-ExpandedArtifact -Id $artifact.id -Digest $artifact.sha256 -Directory $directory
    $kindRoot = Join-Path $packageRoot $artifact.kind
    $null = New-Item -ItemType Directory -Path $kindRoot
    foreach ($file in Get-ChildItem $directory -Recurse -File) {
        if ($file.Extension -cne '.app') { throw 'Unexpected file in package archive.' }
        if (Test-Path (Join-Path $kindRoot $file.Name)) { throw 'Duplicate package file in archive.' }
        Copy-Item $file.FullName (Join-Path $kindRoot $file.Name) -ErrorAction Stop
    }
}
$source = Get-Content (Join-Path $context.output 'source-receipt.json') -Raw | ConvertFrom-Json
Assert-ExpandedApiPackageManifest -Manifest $manifest -Country $context.cell.country -RunId $env:GITHUB_RUN_ID `
    -SourceHead $env:GITHUB_SHA -SourceTree $source.sourceTree -PackageDirectory $packageRoot
foreach ($kind in @('Apps', 'TestApps')) {
    $paths = @(Get-ChildItem (Join-Path $packageRoot $kind) -File | ForEach-Object FullName)
    $list = Join-Path $context.output "$kind.json"
    ConvertTo-Json -InputObject $paths | Set-Content $list
    "$kind=$list" | Add-Content $env:GITHUB_OUTPUT
}
Copy-Item (Join-Path $countryDirectory 'packages.json') (Join-Path $context.output 'packages.json')
@{ registryId = $RegistryId; registrySha256 = $RegistryDigest; countryManifestId = $entry.artifactId
    countryManifestSha256 = $entry.sha256; artifacts = $manifest.artifacts
    transportVerified = $true; packageFilesVerified = $true } |
    ConvertTo-Json -Depth 20 | Set-Content (Join-Path $context.output 'transport-proof.json')
