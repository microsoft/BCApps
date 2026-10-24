$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1')
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Assert-ExpandedApiDispatch
$all = @()
$page = 1
do {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/BCApps/actions/runs/$($env:GITHUB_RUN_ID)/artifacts?per_page=100&page=$page" `
        -Headers @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
    $all += @($response.artifacts)
    $page++
} while ($response.artifacts.Count -eq 100)
$countries = @()
$overlay = Get-Content (Join-Path $PSScriptRoot 'source-overlay.json') -Raw | ConvertFrom-Json
foreach ($country in @('W1', 'DE', 'CA', 'US', 'IT')) {
    $match = @($all | Where-Object name -CEQ "expanded-manifest-$country-$($env:GITHUB_RUN_ID)")
    if ($match.Count -ne 1) { throw 'Missing or duplicate shared-build manifest.' }
    $directory = Join-Path $env:GITHUB_WORKSPACE "expanded-registry-$country"
    $metadata = Save-ExpandedArtifact -Id $match[0].id -Digest $match[0].digest.Substring(7) -Directory $directory
    $manifest = Get-Content (Join-Path $directory 'packages.json') -Raw | ConvertFrom-Json
    $cleanup = Get-Content (Join-Path $directory 'compiler-cleanup.json') -Raw | ConvertFrom-Json
    if ($manifest.country -cne $country -or $manifest.runId -cne $env:GITHUB_RUN_ID -or
        $manifest.sourceHead -cne $env:GITHUB_SHA -or $manifest.sourceTree -cne $overlay.sourceTree -or
        $manifest.overlaySha256 -cne $overlay.overlaySha256 -or $cleanup.compilerRemaining -ne $false) {
        throw 'Compilation provenance or owned compiler cleanup missing.'
    }
    $countries += @{ country = $country; artifactId = [string]$metadata.id
        sha256 = $metadata.digest.Substring(7); packageManifest = $manifest }
}
if (@($countries.packageManifest.sourceTree | Sort-Object -Unique).Count -ne 1 -or
    @($countries.packageManifest.overlaySha256 | Sort-Object -Unique).Count -ne 1) {
    throw 'Country builds compiled different source overlays.'
}
$null = New-Item -ItemType Directory -Path 'expanded-registry'
@{ runId = $env:GITHUB_RUN_ID; sourceHead = $env:GITHUB_SHA; countries = $countries } |
    ConvertTo-Json -Depth 40 | Set-Content 'expanded-registry\registry.json'
