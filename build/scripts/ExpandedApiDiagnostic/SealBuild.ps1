param([string]$AppsId, [string]$AppsDigest, [string]$TestsId, [string]$TestsDigest)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')
Assert-ExpandedApiDispatch
Import-ExpandedHelper
$output = Join-Path $env:GITHUB_WORKSPACE 'expanded-api-output'
$source = Get-Content (Join-Path $output 'source-receipt.json') -Raw | ConvertFrom-Json
$overlay = Get-Content (Join-Path $PSScriptRoot 'source-overlay.json') -Raw | ConvertFrom-Json
if ($source.sourceHead -cne $env:GITHUB_SHA -or $source.runId -cne $env:GITHUB_RUN_ID -or
    $source.sourceTree -cne $overlay.sourceTree -or $source.overlaySha256 -cne $overlay.overlaySha256 -or
    $source.attempt -ne 1) { throw 'Compiler receipt does not match the reviewed source overlay.' }
$root = Join-Path $env:GITHUB_WORKSPACE "$($env:BC_EXPANDED_PROJECT)\.buildartifacts"
$artifacts = @()
$files = @()
foreach ($kind in @('Apps', 'TestApps')) {
    $id = if ($kind -eq 'Apps') { $AppsId } else { $TestsId }
    $digest = if ($kind -eq 'Apps') { $AppsDigest } else { $TestsDigest }
    $metadata = Get-ExpandedArtifact -Id $id
    if ($metadata.digest -cne "sha256:$digest" -or
        $metadata.name -cne "expanded-$kind-$($env:BC_EXPANDED_COUNTRY)-$($env:GITHUB_RUN_ID)") {
        throw 'Uploaded build artifact does not match this compilation.'
    }
    $artifacts += @{ kind = $kind; id = $id; sha256 = $digest; expired = $false; metadata = $metadata }
    foreach ($file in Get-ChildItem (Join-Path $root $kind) -File -Filter '*.app') {
        $app = Get-AppJsonFromAppFile -appFile $file.FullName
        $files += @{ path = "$kind\$($file.Name)"; bytes = $file.Length
            sha256 = (Get-FileHash $file.FullName).Hash.ToLowerInvariant()
            appId = $app.id; appName = $app.name; version = $app.version; dependencies = @($app.dependencies) }
    }
}
$plan = Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')
$expected = @($plan.cells | Where-Object country -CEQ $env:BC_EXPANDED_COUNTRY)[0]
foreach ($appId in @($expected.lanes.routes.appId | Sort-Object -Unique)) {
    if (@($files | Where-Object appId -EQ $appId).Count -ne 1) { throw "Compilation omitted/duplicated test app $appId." }
}
foreach ($kind in @('Apps', 'TestApps')) {
    if (-not @($files | Where-Object { $_.path.StartsWith("$kind\") }).Count) { throw 'Empty compiler output.' }
}
@{
    country = $env:BC_EXPANDED_COUNTRY; runId = $env:GITHUB_RUN_ID; attempt = 1
    sourceHead = $env:GITHUB_SHA; sourceTree = $source.sourceTree; overlaySha256 = $source.overlaySha256
    freshCompilation = $true; pins = Get-ExpandedApiPinSet; artifacts = $artifacts; files = $files
    compilerSettings = (Get-Content (Join-Path $output 'project-settings.json') -Raw | ConvertFrom-Json)
    runner = (Get-Content (Join-Path $output 'clock.json') -Raw | ConvertFrom-Json)
} | ConvertTo-Json -Depth 30 | Set-Content (Join-Path $output 'packages.json')
