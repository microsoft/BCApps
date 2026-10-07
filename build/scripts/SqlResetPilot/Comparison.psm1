function Get-SqlComparisonCell {
    param([ValidateSet('originals', 'replacement')][string]$Mode = 'originals',
        [string]$Arm, [string]$Country, [string]$Trial)
    if ($Mode -eq 'replacement') {
        if ($Arm -notin @('control', 'warmup', 'retry') -or $Country -notin @('W1', 'DE') -or
            $Trial -notmatch '^(?:[1-9]|[1-4][0-9]|50)$') { throw 'Invalid replacement identity.' }
        return [PSCustomObject]@{ experiment = $Arm; country = $Country; trial = [int]$Trial }
    }
    if ($Arm -or $Country -or $Trial) { throw 'Original schedule cannot contain replacement selection.' }
    foreach ($index in 1..50) {
        # Rotate queue order across indices without changing balanced six-cell blocks.
        $countries = if ($index % 2) { @('W1', 'DE') } else { @('DE', 'W1') }
        $arms = @('control', 'warmup', 'retry')
        foreach ($location in $countries) {
            foreach ($offset in 0..2) {
                [PSCustomObject]@{
                    experiment = $arms[($index - 1 + $offset) % 3]
                    country = $location
                    trial = $index
                }
            }
        }
    }
}

function Assert-SqlComparisonReplacement {
    param($Run, $Job, [array]$Annotations, $Cell, [string]$ExpectedSha)
    $identity = "$($Cell.experiment)/$($Cell.country)/$($Cell.trial)"
    if ($Run.head_sha -ne $ExpectedSha -or
        $Run.head_branch -ne 'features/646383-sql-api-300-trial-comparison' -or
        $Run.event -ne 'workflow_dispatch' -or $Run.run_attempt -ne 1 -or
        $Run.path -ne '.github/workflows/CICD.yaml' -or
        $Run.display_title -ne 'SQL API 300 comparison - originals' -or
        $Job.run_id -ne $Run.id -or $Job.conclusion -ne 'failure' -or $Job.status -ne 'completed' -or
        $Job.name -notmatch "(?:^| / )Trial $([regex]::Escape($identity))$") {
        throw 'Replacement must identify a failed original cell from this exact comparison revision.'
    }
    $communication = @($Annotations | Where-Object {
        $_.annotation_level -eq 'failure' -and
        $_.message -match '(?is)self-hosted runner.*lost communication with (?:the )?server'
    })
    if ($communication.Count -eq 0) { throw 'No authoritative runner-communication annotation; no replacement authorized.' }
    [PSCustomObject]@{
        runId = [string]$Run.id; jobId = [string]$Job.id; trialIdentity = $identity
        event = $Run.event; runAttempt = $Run.run_attempt; workflow = $Run.path
        workflowSha = $Run.head_sha; annotation = @($communication.message)
        reason = 'Confirmed GitHub runner communication failure; retained separately from original results'
    }
}

function Get-SqlComparisonArtifact {
    @(
        @{ country = 'W1'; kind = 'apps'; id = '11374170356'; digest = '683343673e6efeb7699734b250d2ee5004d2d83fe08e57f324c4c645c09612db' }
        @{ country = 'W1'; kind = 'tests'; id = '11374145359'; digest = 'f75ce06920437328e5d79a5512eddcc2425624bb696c339c108478c83554171d' }
        @{ country = 'DE'; kind = 'apps'; id = '11376415128'; digest = '409af00bb5e6922224626f94a4d4f5625f4a9bf13b9398e84cc101a41a313dd5' }
        @{ country = 'DE'; kind = 'tests'; id = '11375174896'; digest = '4e1edde77089e0b586679b168f11123a8181a99c63c3a82b42323503340a5d3b' }
    )
}

function Assert-SqlComparisonSnapshot {
    param([string]$Directory, [ValidateSet('W1', 'DE')][string]$Country)
    $proof = @(Get-Content (Join-Path $Directory 'artifact-proof.json') -Raw -ErrorAction Stop | ConvertFrom-Json)
    if ($proof.Count -ne 2) { throw 'Snapshot must contain the two original country artifacts.' }
    foreach ($pin in @(Get-SqlComparisonArtifact | Where-Object country -eq $Country)) {
        $entry = @($proof | Where-Object { $_.pin.id -eq $pin.id })
        if ($entry.Count -ne 1 -or $entry[0].metadata.id -ne $pin.id -or
            $entry[0].metadata.expired -or $entry[0].metadata.workflow_run.id -ne 37372848860 -or
            $entry[0].metadata.workflow_run.head_sha -ne 'c4953dceffe02a017adad34973e1955017bf5d20' -or
            $entry[0].metadata.digest -ne "sha256:$($pin.digest)" -or
            (Get-FileHash (Join-Path $Directory "$($pin.id).zip") -Algorithm SHA256 -ErrorAction Stop).Hash -ne $pin.digest) {
            throw 'Immutable snapshot archive or original provenance differs from the pinned source.'
        }
    }
    return $proof
}

function Save-SqlComparisonSnapshot {
    param([string]$ArtifactId, [string]$RunId, [string]$HeadSha,
        [ValidateSet('W1', 'DE')][string]$Country, [string]$Directory)
    if ($ArtifactId -notmatch '^\d{1,20}$' -or $RunId -notmatch '^\d{1,20}$' -or -not $env:GH_TOKEN) {
        throw 'Explicit snapshot identity and Actions credential are required.'
    }
    $headers = @{ Authorization = "Bearer $env:GH_TOKEN"; Accept = 'application/vnd.github+json' }
    $uri = "https://api.github.com/repos/microsoft/BCApps/actions/artifacts/$ArtifactId"
    $metadata = Invoke-RestMethod $uri -Headers $headers
    if ($metadata.expired -or $metadata.workflow_run.id -ne $RunId -or
        $metadata.workflow_run.head_sha -ne $HeadSha -or
        $metadata.name -ne "sql-api-comparison-packages-$Country-$RunId" -or
        $metadata.digest -notmatch '^sha256:([0-9a-f]{64})$') {
        throw 'Snapshot must be the immutable country package archive from this comparison revision.'
    }
    $digest = $Matches[1]
    $null = New-Item -ItemType Directory -Path $Directory -Force
    $zip = "$Directory.zip"
    Invoke-WebRequest "$uri/zip" -Headers $headers -OutFile $zip -UseBasicParsing
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $digest) { throw 'Snapshot transport hash mismatch.' }
    Expand-Archive $zip $Directory -Force
    Assert-SqlComparisonSnapshot -Directory $Directory -Country $Country
}

Export-ModuleMember -Function Get-SqlComparisonCell, Assert-SqlComparisonReplacement, Get-SqlComparisonArtifact,
    Assert-SqlComparisonSnapshot, Save-SqlComparisonSnapshot
