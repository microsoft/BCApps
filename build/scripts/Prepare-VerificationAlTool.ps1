$ErrorActionPreference = "Stop"
$provenance = Get-Content (Join-Path $PSScriptRoot "VerificationAlTool.json") -Raw | ConvertFrom-Json
$zip = Join-Path $PSScriptRoot "..\tools\altool-dev-net10.zip"
if (-not (Test-Path -LiteralPath $zip -PathType Leaf)) {
    throw "The verified custom ALTool bundle is missing from build\tools\altool-dev-net10.zip."
}
foreach ($field in @("archiveSha256", "exeSha256", "dllSha256", "languageModelToolsSha256", "version")) {
    if (-not $provenance.$field) {
        throw "Custom ALTool provenance '$field' has not been supplied. Do not substitute a released tool."
    }
}

$destination = Join-Path $env:RUNNER_TEMP ("bcapps-altool-" + [guid]::NewGuid().ToString("N"))
$null = New-Item -ItemType Directory -Path $destination
if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $provenance.archiveSha256) {
    throw "Custom ALTool archive hash does not match the verified build."
}
Expand-Archive -LiteralPath $zip -DestinationPath $destination
foreach ($binary in @(@{ Name = "altool.exe"; Hash = $provenance.exeSha256 },
    @{ Name = "altool.dll"; Hash = $provenance.dllSha256 },
    @{ Name = "Microsoft.Dynamics.Nav.LanguageModelTools.dll"; Hash = $provenance.languageModelToolsSha256 })) {
    $path = Join-Path $destination $binary.Name
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
if ($LASTEXITCODE -ne 0 -or ($helpOutput -join "`n") -notmatch '\-\-renewsession\b') {
    throw "Custom ALTool does not advertise the required native --renewsession option."
}
Add-Content -Encoding UTF8 -Path $env:GITHUB_ENV -Value "AlToolPath=$alToolPath"
Write-Host "Using verified native ALTool $($provenance.version), archive SHA256 $($provenance.archiveSha256), with --renewsession."
