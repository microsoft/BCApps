$ErrorActionPreference = 'Stop'
$base = 'c4953dceffe02a017adad34973e1955017bf5d20'
if ($env:GITHUB_REPOSITORY -ne 'microsoft/BCApps' -or
    $env:GITHUB_REF -ne 'refs/heads/features/646383-sql-reset-pilot' -or
    $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch' -or $env:GITHUB_RUN_ATTEMPT -ne '1' -or
    $env:BC_SQL_PILOT_ARM -notin @('control', 'fresh')) {
    throw 'This diagnostic is restricted to its explicitly dispatched disposable CI branch, attempt one.'
}
git merge-base --is-ancestor $base HEAD
if ($LASTEXITCODE -ne 0) { throw 'PR2 base is not an ancestor.' }
git diff --exit-code $base HEAD -- src
if ($LASTEXITCODE -ne 0) { throw 'AL/package source differs from the pinned compiled PR2 source.' }

$output = Join-Path $env:GITHUB_WORKSPACE 'sql-reset-pilot-output'
New-Item -ItemType Directory $output -Force | Out-Null
"BC_SQL_PILOT_OUTPUT=$output" | Add-Content $env:GITHUB_ENV
@{ phase = 'package-preflight'; arm = $env:BC_SQL_PILOT_ARM; run = $env:GITHUB_RUN_ID; utc = [DateTime]::UtcNow.ToString('o') } |
    ConvertTo-Json | Set-Content (Join-Path $output 'start.json') -Encoding UTF8
$headers = @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
$api = 'https://api.github.com/repos/microsoft/BCApps'
$artifacts = @(
    @{ Kind = 'apps'; Id = 11374170356; Digest = '683343673e6efeb7699734b250d2ee5004d2d83fe08e57f324c4c645c09612db' },
    @{ Kind = 'tests'; Id = 11374145359; Digest = 'f75ce06920437328e5d79a5512eddcc2425624bb696c339c108478c83554171d' }
)
$manifest = @()
foreach ($artifact in $artifacts) {
    $metadata = Invoke-RestMethod "$api/actions/artifacts/$($artifact.Id)" -Headers $headers
    if ($metadata.expired -or $metadata.workflow_run.id -ne 37372848860 -or
        $metadata.workflow_run.head_sha -ne $base -or $metadata.digest -ne "sha256:$($artifact.Digest)") {
        throw 'Exact artifact provenance/digest check failed; no moving-build fallback is permitted.'
    }
    $destination = Join-Path $env:GITHUB_WORKSPACE "sql-reset-pilot-packages\$($artifact.Kind)"
    New-Item -ItemType Directory $destination -Force | Out-Null
    $zip = "$destination.zip"
    Invoke-WebRequest "$api/actions/artifacts/$($artifact.Id)/zip" -Headers $headers -OutFile $zip -UseBasicParsing
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $artifact.Digest) { throw 'Artifact archive hash mismatch.' }
    Expand-Archive $zip $destination
    $files = @(Get-ChildItem $destination -Filter '*.app' -Recurse -File | Sort-Object FullName)
    if ($files.Count -eq 0) { throw 'Pinned artifact contains no app packages.' }
    $list = Join-Path $destination 'packages.json'
    ConvertTo-Json -InputObject @($files.FullName) | Set-Content $list -Encoding UTF8
    "$($artifact.Kind)=$list" | Add-Content $env:GITHUB_OUTPUT
    $manifest += @{
        artifactId = $artifact.Id; sourceRun = 37372848860; sourceHead = $base
        kind = $artifact.Kind; archiveSha256 = $artifact.Digest
        files = @($files | ForEach-Object { @{ name = $_.Name; sha256 = (Get-FileHash $_.FullName).Hash } })
    }
}
@{
    experimentHead = $env:GITHUB_SHA; run = $env:GITHUB_RUN_ID; arm = $env:BC_SQL_PILOT_ARM
    budgetMinutes = 120; startedUtc = [DateTime]::UtcNow.ToString('o')
    artifacts = $manifest
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $output 'provenance.json') -Encoding UTF8
