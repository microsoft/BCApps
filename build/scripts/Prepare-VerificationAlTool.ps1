$ErrorActionPreference = "Stop"
$provenance = Get-Content (Join-Path $PSScriptRoot "VerificationAlTool.json") -Raw | ConvertFrom-Json
$zip = Join-Path $PSScriptRoot "..\tools\altool-dev-net10.zip"
if (-not (Test-Path -LiteralPath $zip -PathType Leaf)) {
    throw "The verified custom ALTool bundle is missing from build\tools\altool-dev-net10.zip."
}
foreach ($field in @("archiveSha256", "exeSha256", "dllSha256", "languageModelToolsSha256", "version", "renewSessionScope", "sourceBaseCommit", "stagedSourcePatchSha256", "sourceProvenanceSha256", "sourceScopeSha256")) {
    if (-not $provenance.$field) {
        throw "Custom ALTool provenance '$field' has not been supplied. Do not substitute a released tool."
    }
}
if ($provenance.renewSessionScope -ne "codeunit") {
    throw "Custom ALTool must renew once per ordered codeunit group, not per method."
}
foreach ($field in @("archiveSha256", "exeSha256", "dllSha256", "languageModelToolsSha256", "stagedSourcePatchSha256", "sourceProvenanceSha256", "sourceScopeSha256")) {
    if ($provenance.$field -notmatch '^[0-9a-fA-F]{64}$') {
        throw "Custom ALTool provenance '$field' must be a SHA256 hash."
    }
}
if ($provenance.sourceBaseCommit -notmatch '^[0-9a-fA-F]{40}$') {
    throw "Custom ALTool provenance 'sourceBaseCommit' must be a full Git commit SHA."
}

$destination = Join-Path $env:RUNNER_TEMP ("bcapps-altool-" + [guid]::NewGuid().ToString("N"))
$null = New-Item -ItemType Directory -Path $destination
if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $provenance.archiveSha256) {
    throw "Custom ALTool archive hash does not match the verified build."
}
Expand-Archive -LiteralPath $zip -DestinationPath $destination
foreach ($evidence in @(@{ Name = "provenance.json"; Hash = $provenance.sourceProvenanceSha256 },
    @{ Name = "minimal-source.patch"; Hash = $provenance.stagedSourcePatchSha256 },
    @{ Name = "source-scope.json"; Hash = $provenance.sourceScopeSha256 })) {
    if ((Get-FileHash -LiteralPath (Join-Path $destination $evidence.Name) -Algorithm SHA256).Hash -ne $evidence.Hash) {
        throw "Custom ALTool $($evidence.Name) hash does not match the verified source evidence."
    }
}
$sourceProvenance = Get-Content (Join-Path $destination "provenance.json") -Raw | ConvertFrom-Json
if ($sourceProvenance.baseSha -ne $provenance.sourceBaseCommit -or
    $sourceProvenance.sourceDiff.sha256 -ne $provenance.stagedSourcePatchSha256) {
    throw "Custom ALTool source pins do not match the embedded build provenance."
}
foreach ($binary in @(@{ Name = "altool.exe"; Hash = $provenance.exeSha256 },
    @{ Name = "altool.dll"; Hash = $provenance.dllSha256 },
    @{ Name = "Microsoft.Dynamics.Nav.LanguageModelTools.dll"; Hash = $provenance.languageModelToolsSha256 })) {
    $path = Join-Path $destination $binary.Name
    $sourceBinary = @($sourceProvenance.files | Where-Object { $_.path -ceq $binary.Name })
    if ($sourceBinary.Count -ne 1 -or $sourceBinary[0].sha256 -ne $binary.Hash) {
        throw "Custom ALTool $($binary.Name) pin does not match the embedded build provenance."
    }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $binary.Hash) {
        throw "Custom ALTool $($binary.Name) hash does not match the verified build."
    }
}
$alToolPath = Join-Path $destination "altool.exe"
$versionOutput = @(& $alToolPath --version 2>&1)
if ($LASTEXITCODE -ne 0 -or ($versionOutput -join "`n").Trim() -ne $provenance.version) {
    throw "Custom ALTool version does not match the verified build: $($versionOutput -join ' ')."
}
$helpOutput = @(& $alToolPath runtests --help 2>&1)
$helpText = $helpOutput -join "`n"
if ($LASTEXITCODE -ne 0 -or $helpText -notmatch '(?m)--renewsession(?=\s|$)' -or
    $helpText -notmatch '(?m)--renewsession-per-method(?=\s|$)') {
    throw "Custom ALTool must advertise --renewsession and the separate --renewsession-per-method option."
}
Add-Content -Encoding UTF8 -Path $env:GITHUB_ENV -Value "AlToolPath=$alToolPath"
Write-Host "Using verified native ALTool $($provenance.version), archive SHA256 $($provenance.archiveSha256), with --renewsession (one session per ordered codeunit group)."
