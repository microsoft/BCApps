Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')

function Get-ExpandedArtifact {
    param([Parameter(Mandatory)][string]$Id,
        [string]$ExpectedRunId = $env:GITHUB_RUN_ID, [string]$ExpectedHead = $env:GITHUB_SHA)
    Assert-ExpandedApiDispatch
    if ($Id -notmatch '^[1-9]\d{0,19}$') { throw 'Invalid artifact id.' }
    $metadata = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/BCApps/actions/artifacts/$Id" `
        -Headers @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
    if ([string]$metadata.id -cne $Id -or $metadata.expired -isnot [bool] -or $metadata.expired -or
        [string]$metadata.workflow_run.id -cne $ExpectedRunId -or
        $metadata.workflow_run.head_sha -cne $ExpectedHead -or
        $metadata.digest -notmatch '^sha256:[a-f0-9]{64}$') { throw 'Artifact is expired or from another run/source.' }
    $metadata
}

function Save-ExpandedArtifact {
    param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Digest,
        [Parameter(Mandatory)][string]$Directory,
        [string]$ExpectedRunId = $env:GITHUB_RUN_ID, [string]$ExpectedHead = $env:GITHUB_SHA)
    $metadata = Get-ExpandedArtifact -Id $Id -ExpectedRunId $ExpectedRunId -ExpectedHead $ExpectedHead
    if ($metadata.digest -cne "sha256:$Digest") { throw 'Sealed artifact transport digest drift.' }
    if (Test-Path $Directory) { throw 'Artifact destination already exists.' }
    $null = New-Item -ItemType Directory -Path $Directory
    $zip = "$Directory.zip"
    if (Test-Path $zip) { throw 'Artifact archive destination already exists.' }
    Invoke-WebRequest -Uri "https://api.github.com/repos/microsoft/BCApps/actions/artifacts/$Id/zip" `
        -Headers @{ Authorization = "Bearer $env:GH_TOKEN" } -OutFile $zip
    if ((Get-FileHash $zip).Hash.ToLowerInvariant() -cne $Digest) { throw 'Downloaded artifact hash mismatch.' }
    # Check every entry before extraction; no archive may escape its owned directory.
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -match '(^[/\\]|(^|[/\\])\.\.([/\\]|$)|:)') { throw 'Unsafe archive path.' }
        }
    } finally { $archive.Dispose() }
    Expand-Archive -LiteralPath $zip -DestinationPath $Directory
    $metadata
}

Export-ModuleMember -Function Get-ExpandedArtifact, Save-ExpandedArtifact
