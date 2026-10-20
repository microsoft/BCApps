Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Invoke-BackportProcess {
    param(
        [string] $Command,
        [string[]] $Arguments,
        [string] $Directory = (Get-Location).Path,
        [string] $InputText = '',
        [hashtable] $Environment = @{},
        [switch] $AllowFailure
    )

    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Command
    $info.WorkingDirectory = $Directory
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
    foreach ($argument in $Arguments) { [void]$info.ArgumentList.Add($argument) }
    foreach ($key in $Environment.Keys) {
        if ($null -eq $Environment[$key]) { [void]$info.Environment.Remove($key) }
        else { $info.Environment[$key] = $Environment[$key] }
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    try {
        if (-not $process.Start()) { throw "Unable to start $Command." }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.StandardInput.Write($InputText)
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(600000)) {
            $process.Kill($true)
            throw "$Command exceeded its ten-minute deadline."
        }
        $text = $stdout.GetAwaiter().GetResult()
        $errorText = $stderr.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0 -and -not $AllowFailure) {
            throw "$Command failed (exit $($process.ExitCode)): $errorText"
        }
        return @{ exit_code = $process.ExitCode; text = $text }
    }
    finally { $process.Dispose() }
}

function Invoke-BackportApi {
    param([string] $Path, [string] $Method = 'GET', [hashtable] $Body)

    $arguments = @('api', '--hostname', 'github.com', '--method', $Method, $Path)
    $inputText = ''
    if ($null -ne $Body) {
        $arguments += @('--input', '-')
        $inputText = ConvertTo-Json $Body -Depth 30 -Compress
    }
    $result = Invoke-BackportProcess -Command gh -Arguments $arguments -InputText $inputText
    if (-not [string]::IsNullOrWhiteSpace($result.text)) {
        return ConvertFrom-Json $result.text -AsHashtable -Depth 50
    }
}

function Get-BackportApiPages {
    param([string] $Path)

    $separator = if ($Path.Contains('?')) { '&' } else { '?' }
    for ($page = 1; ; $page++) {
        $items = @(Invoke-BackportApi "$Path${separator}per_page=100&page=$page")
        foreach ($item in $items) { $item }
        if ($items.Count -lt 100) { break }
    }
}

function Assert-BackportRepository {
    param([string] $Repository)
    if ($Repository -cne 'microsoft/BCApps') { throw 'Backports are supported only in microsoft/BCApps.' }
}

function Assert-BackportTarget {
    param([string] $Target)
    if ($Target -cnotmatch '^releases/([1-9][0-9]*)\.x$') {
        throw "Invalid release branch '$Target'; expected releases/<number>.x."
    }
}

function Get-BackportLatestTarget {
    param([string[]] $Branches, [string] $Override = '')

    if (-not [string]::IsNullOrWhiteSpace($Override)) {
        Assert-BackportTarget $Override
        if ($Override -cnotin $Branches) { throw "Configured target '$Override' does not exist." }
        return $Override
    }
    $targets = @($Branches | Where-Object { $_ -cmatch '^releases/[1-9][0-9]*\.x$' } |
        Sort-Object { [long](($_ -split '/')[1] -split '\.')[0] } -Descending)
    if ($targets.Count -eq 0) { throw 'No releases/<number>.x branch exists.' }
    return $targets[0]
}

function Test-BackportCategory {
    param([string[]] $Labels)

    $allowed = @('event-request', 'request-for-external')
    $other = @($Labels | Where-Object {
        $_ -notin $allowed -and
        ($_ -match '-request$' -or $_ -like 'request-for-*' -or
         $_ -in @('extensibility-enhancement', 'extensibility-bug'))
    })
    return @($Labels | Where-Object { $_ -in $allowed }).Count -gt 0 -and
        $other.Count -eq 0 -and $Labels -notcontains 'ext-backporting' -and
        $Labels -notcontains 'ext-backport-processed'
}

function Test-BackportAutomaticSource {
    param([hashtable] $Source, [DateTimeOffset] $Now = [DateTimeOffset]::UtcNow)

    if ($null -eq $Source.merged_at -or $Source.base.ref -cne 'main') { return $false }
    $merged = [DateTimeOffset]$Source.merged_at
    return $merged -ge $Now.AddDays(-15) -and $merged -le $Now -and
        (Test-BackportCategory @($Source.labels | ForEach-Object { $_.name }))
}

function Find-ExtRequestBackport {
    [CmdletBinding()]
    param([string] $Repository, [string] $SourcePr = '', [string] $TargetOverride = '',
        [DateTimeOffset] $ReferenceTime = [DateTimeOffset]::UtcNow)

    Assert-BackportRepository $Repository
    $branches = @(Get-BackportApiPages "repos/$Repository/branches" | ForEach-Object { $_.name })
    $target = Get-BackportLatestTarget -Branches $branches -Override $TargetOverride
    if (-not [string]::IsNullOrWhiteSpace($SourcePr)) {
        if ($SourcePr -cnotmatch '^[1-9][0-9]{0,9}$') { throw 'source_pr must be a positive PR number.' }
        return @{ source_pr = [long]$SourcePr; target = $target }
    }

    $now = $ReferenceTime
    $sources = [Collections.Generic.List[object]]::new()
    for ($page = 1; ; $page++) {
        $items = @(Invoke-BackportApi "repos/$Repository/pulls?state=closed&base=main&sort=updated&direction=desc&per_page=100&page=$page")
        foreach ($source in $items) {
            if (Test-BackportAutomaticSource -Source $source -Now $now) { $sources.Add($source) }
        }
        if ($items.Count -lt 100 -or [DateTimeOffset]$items[-1].updated_at -lt $now.AddDays(-15)) { break }
    }
    if ($sources.Count -gt 256) { throw 'More than 256 eligible PRs; use manual runs to reduce the backlog.' }
    foreach ($source in ($sources | Sort-Object { [DateTimeOffset]$_.merged_at }, number)) {
        @{ source_pr = [long]$source.number; target = $target }
    }
}

function Get-BackportSource {
    param([string] $Repository, [long] $Number)

    $source = Invoke-BackportApi "repos/$Repository/pulls/$Number"
    if ($null -eq $source.merged_at -or $source.base.ref -cne 'main' -or
        $source.base.repo.full_name -cne $Repository -or $source.merge_commit_sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "PR #$Number must be merged into $Repository main."
    }
    return $source
}

function Get-BackportSourceIssues {
    param([string] $Repository, [long] $Number)

    $parts = $Repository.Split('/')
    $query = @'
query($owner:String!,$repo:String!,$number:Int!,$cursor:String) {
  repository(owner:$owner,name:$repo) {
    pullRequest(number:$number) {
      closingIssuesReferences(first:100,after:$cursor) {
        nodes { number url title repository { nameWithOwner }
          labels(first:100) { nodes { name color description } pageInfo { hasNextPage } }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
'@
    $cursor = $null
    do {
        $response = Invoke-BackportApi -Path graphql -Method POST -Body @{
            query = $query
            variables = @{ owner = $parts[0]; repo = $parts[1]; number = $Number; cursor = $cursor }
        }
        if ($response.ContainsKey('errors')) { throw 'Could not read all source issue references.' }
        $connection = $response.data.repository.pullRequest.closingIssuesReferences
        if ($null -eq $connection) { throw 'Source issue references are unavailable.' }
        foreach ($issue in $connection.nodes) {
            if ($issue.labels.pageInfo.hasNextPage) { throw "Issue $($issue.url) has more than 100 labels." }
            $issue
        }
        $cursor = $connection.pageInfo.endCursor
    } while ($connection.pageInfo.hasNextPage)
}

function Get-BackportLabels {
    param([object[]] $Issues, [object[]] $PrLabels)

    $labels = @{}
    $original = if ($Issues.Count -gt 0) {
        @($Issues | ForEach-Object { $_.labels.nodes })
    }
    else { @($PrLabels | Where-Object { $_.name -ne 'ext-backport-processed' }) }
    foreach ($label in $original) {
        if ($label.name -ne 'ext-ready-to-implement') { $labels[$label.name] = $label }
    }
    $labels['ext-backporting'] = @{ name = 'ext-backporting'; color = '5319E7'; description = 'Tracks an extensibility backport.' }
    return @($labels.Values | Sort-Object name)
}

function Get-BackportMarker {
    param([long] $SourcePr, [string] $Target, [string] $Sha)
    "<!-- bc-extrequest-backport:v1 source=$SourcePr target=$Target sha=$Sha -->"
}

function Read-BackportMarker {
    param([string] $Body)
    $matches = [regex]::Matches($Body,
        '(?m)^<!-- bc-extrequest-backport:v1 source=([1-9][0-9]*) target=(releases/[1-9][0-9]*\.x) sha=([0-9a-f]{40}) -->\r?$')
    if ($matches.Count -gt 1) { throw 'Multiple backport identities on one object.' }
    if ($matches.Count -eq 0) { return $null }
    return @{ source_pr = [long]$matches[0].Groups[1].Value; target = $matches[0].Groups[2].Value; sha = $matches[0].Groups[3].Value }
}

function Get-BackportTracking {
    param([string] $Repository, [long] $SourcePr)

    $matches = @(Get-BackportApiPages "repos/$Repository/issues?state=all&labels=ext-backporting" |
        Where-Object {
            if ($_.ContainsKey('pull_request')) { return $false }
            $batch = Read-BackportBatchMarker $_.body
            if ($null -ne $batch -and @($batch.members | Where-Object {
                $_.source_pr -eq $SourcePr -and $_.result.outcome -eq 'applied'
            }).Count -gt 0) { throw "Source #$SourcePr belongs to batch $($batch.request.key); use the batch API to reconcile it." }
            $marker = Read-BackportMarker $_.body
            return $null -ne $marker -and $marker.source_pr -eq $SourcePr
        })
    if ($matches.Count -gt 1) { throw "Multiple tracking issues for source PR #$SourcePr; reconcile manually." }
    if ($matches.Count -eq 1) { return $matches[0] }
    return $null
}

function Get-BackportPinnedTarget {
    param([hashtable] $Source, [AllowNull()][hashtable] $Tracking, [string] $Default)

    if ($null -ne $Tracking) {
        $marker = Read-BackportMarker $Tracking.body
        if ($marker.sha -cne $Source.merge_commit_sha) { throw 'Tracking issue source SHA has changed.' }
        return $marker.target
    }
    $targets = @($Source.labels | ForEach-Object {
        if ($_.name -match '^ext-backport-(?:pending|publishing|created|needs-attention|merged|already-present):([1-9][0-9]*\.x)$') {
            "releases/$($Matches[1])"
        }
    } | Sort-Object -Unique)
    if ($targets.Count -gt 1) { throw 'Source PR has backport state for multiple targets.' }
    if ($targets.Count -eq 1) { return $targets[0] }
    return $Default
}

function Get-BackportBranch {
    param([long] $SourcePr, [string] $Target)
    "bc-extrequest-backport/pr-$SourcePr/$(($Target -split '/')[1])"
}

function Get-BackportPull {
    param([string] $Repository, [long] $SourcePr, [string] $Target)

    $branch = Get-BackportBranch $SourcePr $Target
    $owner = $Repository.Split('/')[0]
    $pulls = @(Get-BackportApiPages "repos/$Repository/pulls?state=all&head=$owner`:$branch")
    if ($pulls.Count -gt 1) { throw 'Multiple backport PRs for the same branch.' }
    if ($pulls.Count -eq 1) { return $pulls[0] }
    return $null
}

function Invoke-BackportGit {
    param(
        [string] $Directory, [string[]] $Arguments, [string] $InputText = '',
        [switch] $AllowFailure, [string] $CommitDate = ''
    )

    $environment = @{
        GIT_CONFIG_NOSYSTEM = '1'; GIT_CONFIG_GLOBAL = (Join-Path $Directory '.git/empty-config')
        GIT_DIR = $null; GIT_WORK_TREE = $null; GIT_INDEX_FILE = $null
        GIT_OBJECT_DIRECTORY = $null; GIT_ALTERNATE_OBJECT_DIRECTORIES = $null
        GIT_CONFIG = $null; GIT_CONFIG_PARAMETERS = $null; GIT_CONFIG_COUNT = '0'
        GIT_TERMINAL_PROMPT = '0'; GIT_ATTR_NOSYSTEM = '1'
        GIT_AUTHOR_NAME = 'BC Extensibility Backport'; GIT_AUTHOR_EMAIL = 'noreply@github.com'
        GIT_COMMITTER_NAME = 'BC Extensibility Backport'; GIT_COMMITTER_EMAIL = 'noreply@github.com'
        GIT_AUTHOR_DATE = $null; GIT_COMMITTER_DATE = $null
    }
    if ($CommitDate) { $environment.GIT_COMMITTER_DATE = $CommitDate }
    if (-not [string]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
        $authorization = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("x-access-token:$env:GH_TOKEN"))
        $environment.GIT_CONFIG_COUNT = '1'
        $environment.GIT_CONFIG_KEY_0 = 'http.https://github.com/.extraheader'
        $environment.GIT_CONFIG_VALUE_0 = "AUTHORIZATION: basic $authorization"
    }
    $argumentsForGit = @('-c', 'core.autocrlf=false', '-c', 'commit.gpgSign=false',
        '-c', "core.hooksPath=$(Join-Path $Directory '.git/no-hooks')",
        '-c', 'credential.helper=', '-c', 'protocol.file.allow=never', '--literal-pathspecs') + $Arguments
    return Invoke-BackportProcess -Command git -Directory $Directory -Arguments $argumentsForGit `
        -InputText $InputText -Environment $environment -AllowFailure:$AllowFailure
}

function Assert-BackportPaths {
    param([string] $RawDiff)

    $parts = $RawDiff.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries)
    $paths = [Collections.Generic.List[string]]::new()
    if ($parts.Count -eq 0 -or $parts.Count % 2 -ne 0) { throw 'Empty or malformed source diff.' }
    for ($index = 0; $index -lt $parts.Count; $index += 2) {
        if ($parts[$index] -cnotmatch '^:(000000|100644) (000000|100644) [0-9a-f]{40} [0-9a-f]{40} [ADM]$') {
            throw 'Backports accept only additions, modifications and deletions of regular non-executable files.'
        }
        $path = $parts[$index + 1]
        if (-not $path.StartsWith('src/', [StringComparison]::Ordinal) -or
            $path -match '[\x00-\x1f\x7f\\:*?\[\]]' -or
            @($path.Split('/') | Where-Object { $_ -eq '' -or $_ -in @('.', '..') -or $_ -like '.git*' }).Count -gt 0) {
            throw "Unsupported source path '$path'; only safe src/ paths may be backported."
        }
        $paths.Add($path)
    }
    if ($paths.Count -gt 250) { throw 'The source PR changes more than 250 paths.' }
    return $paths.ToArray()
}

function Invoke-BackportApply {
    param([string] $Directory, [string] $SourceSha, [string] $TargetSha, [string[]] $BlockedPaths = @())

    $parents = (Invoke-BackportGit $Directory @('rev-list', '--parents', '-n', '1', $SourceSha)).text.Trim().Split(' ')
    if ($parents.Count -ne 2) { throw 'Only squash-merged source PRs are supported.' }
    $raw = (Invoke-BackportGit $Directory @('diff', '--raw', '--no-abbrev', '--no-renames', '-z', $parents[1], $SourceSha)).text
    $paths = @(Assert-BackportPaths $raw)
    # Do not let a later three-way pick silently recover pieces of an excluded source.
    # Disjoint paths may still proceed; overlapping paths need independent human review.
    if (@($paths | Where-Object { $_ -cin $BlockedPaths }).Count -gt 0) {
        return @{ outcome = 'conflict'; paths = $paths; commit = $null; tree = $null; target_sha = $TargetSha }
    }
    $patterns = ($paths | ForEach-Object { "/$_" }) -join "`n"
    $null = Invoke-BackportGit $Directory @('sparse-checkout', 'set', '--no-cone', '--stdin') -InputText "$patterns`n"
    $null = Invoke-BackportGit $Directory @('checkout', '--detach', $TargetSha)
    $patchPath = Join-Path $Directory '.git/source.patch'
    $null = Invoke-BackportGit $Directory @('diff', '--binary', '--no-ext-diff', '--no-textconv',
        "--output=$patchPath", $parents[1], $SourceSha)
    $reverse = Invoke-BackportGit $Directory @('apply', '--reverse', '--check', '--binary', $patchPath) -AllowFailure
    if ($reverse.exit_code -eq 0) {
        return @{
            outcome = 'already-present'; paths = $paths; commit = $null; target_sha = $TargetSha
            tree = (Invoke-BackportGit $Directory @('rev-parse', 'HEAD^{tree}')).text.Trim()
        }
    }
    # Recomputing an interrupted publication must produce the same commit ID.
    $commitDate = (Invoke-BackportGit $Directory @('show', '-s', '--format=%cI', $SourceSha)).text.Trim()
    $picked = Invoke-BackportGit $Directory @('cherry-pick', '-x', $SourceSha) -AllowFailure -CommitDate $commitDate
    if ($picked.exit_code -ne 0) {
        $conflicts = (Invoke-BackportGit $Directory @('diff', '--name-only', '--diff-filter=U', '-z')).text
        if (-not [string]::IsNullOrEmpty($conflicts)) {
            $null = Invoke-BackportGit $Directory @('cherry-pick', '--abort')
            return @{ outcome = 'conflict'; paths = $paths; commit = $null; tree = $null; target_sha = $TargetSha }
        }
        throw 'Cherry-pick failed without a proven conflict or already-present patch.'
    }
    $commit = (Invoke-BackportGit $Directory @('rev-parse', 'HEAD')).text.Trim()
    $parent = (Invoke-BackportGit $Directory @('rev-parse', 'HEAD^')).text.Trim()
    if ($parent -cne $TargetSha) { throw 'Backport commit does not have the pinned release parent.' }
    $changed = (Invoke-BackportGit $Directory @('diff', '--name-only', '--no-renames', '-z', $TargetSha, $commit)).text
    foreach ($path in $changed.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries)) {
        if ($path -cnotin $paths) { throw 'Backport changed a path outside the source PR.' }
    }
    return @{
        outcome = 'applied'; paths = $paths; commit = $commit; target_sha = $TargetSha
        tree = (Invoke-BackportGit $Directory @('rev-parse', 'HEAD^{tree}')).text.Trim()
    }
}

function Write-BackportSummary {
    param([string] $Text)
    Write-Host $Text
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

function New-ExtRequestBackport {
    [CmdletBinding()]
    param([string] $Repository, [long] $SourcePr, [string] $Target, [bool] $Manual, [string] $StatePath,
        [DateTimeOffset] $ReferenceTime = [DateTimeOffset]::UtcNow)

    Assert-BackportRepository $Repository
    $batch = @(Get-BackportBatchRecords $Repository | Where-Object { $SourcePr -in $_.manifest.request.source_prs })
    if ($batch.Count -gt 0) {
        $row = @{} + $batch[0].manifest.request
        $row.manifest = $batch[0].manifest
        New-ExtRequestBackportBatch $Repository (ConvertTo-Json $row -Depth 60) $StatePath
        return
    }
    $source = Get-BackportSource $Repository $SourcePr
    $issues = @(Get-BackportSourceIssues $Repository $SourcePr)
    $labels = @(Get-BackportLabels -Issues $issues -PrLabels $source.labels)
    $tracking = Get-BackportTracking $Repository $SourcePr
    if (-not $Manual -and $null -eq $tracking -and (-not (Test-BackportAutomaticSource $source $ReferenceTime) -or
        @($issues | Where-Object { -not (Test-BackportCategory @($_.labels.nodes | ForEach-Object { $_.name })) }).Count -gt 0)) {
        throw "Source PR #$SourcePr or one of its issues is no longer automatically eligible."
    }
    $target = Get-BackportPinnedTarget -Source $source -Tracking $tracking -Default $Target
    Assert-BackportTarget $target
    $pull = Get-BackportPull $Repository $SourcePr $target
    $result = @{ outcome = 'existing'; target_sha = $null; commit = $null; tree = $null; paths = @() }
    if ($null -eq $pull -and $null -ne $tracking) {
        foreach ($outcome in @('conflict', 'already-present')) {
            if ($tracking.body.Contains("Preparation result: **$outcome**.") -and
                -not ($outcome -eq 'conflict' -and $Manual -and $tracking.state -ne 'closed')) {
                $result.outcome = $outcome
            }
        }
    }
    $directory = Join-Path (Split-Path -Parent $StatePath) 'git'
    $publicationBlocked = $null -ne $tracking -and $null -ne (Read-BackportPublicationIntent $tracking.body)
    if ($null -eq $pull -and $result.outcome -eq 'existing' -and -not $publicationBlocked) {
        if (Test-Path -LiteralPath $directory) { throw 'Backport work directory already exists.' }
        $null = New-Item -ItemType Directory -Path $directory -Force
        $null = Invoke-BackportGit $directory @('init', '--quiet')
        [IO.File]::WriteAllText((Join-Path $directory '.git/empty-config'), '')
        [IO.File]::WriteAllText((Join-Path $directory '.git/info/attributes'),
            "* -filter -ident -text !eol !working-tree-encoding !merge`n")
        $null = Invoke-BackportGit $directory @('remote', 'add', 'origin', "https://github.com/$Repository.git")
        $release = Invoke-BackportApi "repos/$Repository/git/ref/heads/$target"
        $comparison = Invoke-BackportApi "repos/$Repository/compare/$($source.merge_commit_sha)...main"
        if ($comparison.status -notin @('ahead', 'identical')) { throw 'Source merge is not on current main.' }
        $targetSha = $release.object.sha
        $branch = Get-BackportBranch $SourcePr $target
        $existingHead = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
        if ($existingHead) {
            if ($null -eq $tracking) { throw 'An existing backport branch has no tracking issue; reconcile manually.' }
            $existingSha = ($existingHead -split '\s+')[0]
            $null = Invoke-BackportGit $directory @('fetch', '--quiet', '--no-tags', '--filter=blob:none', '--depth=2',
                'origin', "$existingSha`:refs/backport/existing")
            $targetSha = (Invoke-BackportGit $directory @('rev-parse', "$existingSha^")).text.Trim()
            $comparison = Invoke-BackportApi "repos/$Repository/compare/$targetSha...$target"
            if ($comparison.status -notin @('ahead', 'identical')) { throw 'Existing backport parent is no longer on the release branch.' }
        }
        $null = Invoke-BackportGit $directory @('fetch', '--quiet', '--no-tags', '--filter=blob:none', '--depth=2', 'origin',
            "$($source.merge_commit_sha):refs/backport/source", "$targetSha`:refs/backport/target")
        $result = Invoke-BackportApply $directory $source.merge_commit_sha $targetSha
        if ($existingHead -and $result.commit -cne $existingSha) { throw 'Existing backport branch does not match the source; never overwrite it.' }
    }
    $state = @{
        schema = 1; repository = $Repository; source_pr = $SourcePr; source_sha = $source.merge_commit_sha
        target = $target; manual = $Manual; labels = $labels; issues = $issues; source_title = $source.title
        reference_time = $ReferenceTime.ToUniversalTime().ToString('o')
        result = $result
    }
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $StatePath) -Force
    $state | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
    $issueLinks = if ($issues.Count -gt 0) { ($issues | ForEach-Object { $_.url }) -join ', ' } else { '(none)' }
    $teams = @($source.labels | ForEach-Object { $_.name } | Where-Object { $_ -clike 'Team: *' })
    $teamText = if ($teams.Count -gt 0) { ($teams -join ', ') -replace '[\r\n]', ' ' } else { '(none)' }
    Write-BackportSummary "Main PR #$SourcePr (https://github.com/$Repository/pull/$SourcePr) -> $target`: **$($result.outcome)**. Main PR teams: $teamText. Source issues: $issueLinks"
}

function Ensure-BackportLabels {
    param([string] $Repository, [object[]] $Labels)

    $existing = @(Get-BackportApiPages "repos/$Repository/labels" | ForEach-Object { $_.name })
    foreach ($label in $Labels) {
        if ($label.name -notin $existing) {
            $null = Invoke-BackportApi "repos/$Repository/labels" -Method POST -Body @{
                name = $label.name; color = $label.color; description = [string]$label.description
            }
            $existing += $label.name
        }
    }
}

function Set-BackportProcessed {
    param([string] $Repository, [long] $SourcePr)
    Ensure-BackportLabels $Repository @(@{
        name = 'ext-backport-processed'; color = 'C5DEF5'
        description = 'Source PR has a validated extensibility backport PR.'
    })
    $null = Invoke-BackportApi "repos/$Repository/issues/$SourcePr/labels" -Method POST -Body @{
        labels = @('ext-backport-processed')
    }
}

function New-BackportTrackingTask {
    param([string] $Repository, [hashtable] $Body)
    try {
        $created = Invoke-BackportApi "repos/$Repository/issues" -Method POST -Body $Body
        return Invoke-BackportApi "repos/$Repository/issues/$($created.number)"
    }
    catch {
        throw "Tracking Task creation is unconfirmed. No creation retry was attempted; inspect open/closed objects before another run. $($_.Exception.Message)"
    }
}

function Read-BackportPublicationIntent {
    param([string] $Body)
    $matches = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:publication-intent:v1 sha=([0-9a-f]{40}) -->\r?$')
    if ($matches.Count -gt 1 -or ($matches.Count -eq 0 -and $Body.Contains('bc-extrequest-backport:publication-intent:'))) {
        throw 'Malformed or ambiguous tracking issue publication intent.'
    }
    if ($matches.Count -eq 1) { return $matches[0].Groups[1].Value }
    return $null
}

function Set-BackportPublicationIntent {
    param([hashtable] $State, [hashtable] $Tracking, [string] $Sha, [string] $BotLogin)
    $repository = $State.repository
    $fresh = Invoke-BackportApi "repos/$repository/issues/$($Tracking.number)"
    if ($State.schema -eq 2) { Assert-BackportBatchObject $fresh $State $BotLogin }
    else { Assert-BackportObject $fresh $State $BotLogin }
    if ($null -ne (Read-BackportPublicationIntent $fresh.body)) {
        throw 'Previous PR creation is unconfirmed; reconcile the tracking issue publication intent before retrying.'
    }
    $marker = "<!-- bc-extrequest-backport:publication-intent:v1 sha=$Sha -->"
    $null = Invoke-BackportApi "repos/$repository/issues/$($Tracking.number)" -Method PATCH -Body @{
        body = "$($fresh.body)`n`n$marker"
    }
    $confirmed = Invoke-BackportApi "repos/$repository/issues/$($Tracking.number)"
    if ($State.schema -eq 2) { Assert-BackportBatchObject $confirmed $State $BotLogin }
    else { Assert-BackportObject $confirmed $State $BotLogin }
    if ((Read-BackportPublicationIntent $confirmed.body) -cne $Sha) { throw 'Tracking issue publication intent was not confirmed.' }
    return $confirmed
}

function Assert-BackportObject {
    param([hashtable] $Object, [hashtable] $State, [string] $BotLogin)

    $marker = Read-BackportMarker $Object.body
    if ($null -eq $marker -or $marker.source_pr -ne $State.source_pr -or
        $marker.target -cne $State.target -or $marker.sha -cne $State.source_sha -or
        $Object.user.login -cne $BotLogin) {
        throw 'Existing backport object has an unexpected identity or author.'
    }
    if ($Object.ContainsKey('head') -and
        ($Object.base.ref -cne $State.target -or $Object.base.repo.full_name -cne $State.repository -or
         $Object.head.ref -cne (Get-BackportBranch $State.source_pr $State.target) -or
         $Object.head.repo.full_name -cne $State.repository)) {
        throw 'Existing backport PR has an unexpected source or target.'
    }
}

function Get-BackportBody {
    param([hashtable] $State, [AllowNull()][long] $TrackingNumber = 0)

    $repository = $State.repository
    $lines = @(
        (Get-BackportMarker $State.source_pr $State.target $State.source_sha)
        ''
        "Backport of https://github.com/$repository/pull/$($State.source_pr) to ``$($State.target)``."
        ''
        "Source merge: ``$($State.source_sha)``"
        ''
        '## Original main issues'
    )
    if ($State.issues.Count -eq 0) { $lines += 'No closing issue references were found on the main PR; labels are inherited from that PR.' }
    foreach ($issue in $State.issues) { $lines += "- $($issue.url)" }
    $lines += @('', '## Backport', '', "Preparation result: **$($State.result.outcome)**.")
    if ($TrackingNumber -gt 0) {
        $lines += @('', "Backport tracking issue: https://github.com/$repository/issues/$TrackingNumber", '',
            'Review the complete change and run the normal release-branch CI before merging. No AI resolver was used.')
    }
    elseif ($State.result.outcome -eq 'conflict') {
        $lines += @('', 'The complete source PR could not be cherry-picked cleanly. No partial branch or PR was published.',
            'A developer must resolve the backport manually; automatic runs do not retry this conflict.')
    }
    return $lines -join "`n"
}

function Complete-BackportPull {
    param([hashtable] $State, [hashtable] $Tracking, [hashtable] $Pull, [string] $BotLogin)

    Assert-BackportObject $Tracking $State $BotLogin
    Assert-BackportObject $Pull $State $BotLogin
    $expectedCommit = if ($State.ContainsKey('result')) { $State.result.commit } else { $null }
    if (-not $Pull.ContainsKey('head') -or $Pull.head.sha -cnotmatch '^[0-9a-f]{40}$' -or
        ($expectedCommit -and $Pull.head.sha -cne $expectedCommit)) {
        throw 'Existing backport PR does not contain the expected prepared commit.'
    }
    $repository = $State.repository
    $labels = if ($State.ContainsKey('labels')) { $State.labels } else { $Tracking.labels }
    Ensure-BackportLabels $repository $labels
    foreach ($number in @($Tracking.number, $Pull.number)) {
        $null = Invoke-BackportApi "repos/$repository/issues/$number/labels" -Method POST -Body @{
            labels = @($labels | ForEach-Object { $_.name })
        }
    }
    $body = $Tracking.body
    $link = "Backport PR: $($Pull.html_url)"
    if (-not $body.Contains($link)) {
        $null = Invoke-BackportApi "repos/$repository/issues/$($Tracking.number)" -Method PATCH -Body @{ body = "$body`n`n$link" }
    }
    Set-BackportProcessed $repository $State.source_pr
    Write-BackportSummary "Main PR #$($State.source_pr): validated backport $($Pull.html_url); issue $($Tracking.html_url)."
}

function Publish-ExtRequestBackport {
    [CmdletBinding()]
    param([string] $StatePath, [string] $BotLogin, [hashtable] $PreparedState)

    $state = if ($null -ne $PreparedState) { $PreparedState }
        else { Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -AsHashtable -Depth 60 }
    if ($state.schema -eq 2) { Publish-ExtRequestBackportBatch $StatePath $BotLogin; return }
    if ($state.schema -ne 1 -or $BotLogin -cnotmatch '^[a-z0-9-]+\[bot\]$') { throw 'Invalid publication state or App identity.' }
    Assert-BackportRepository $state.repository
    Assert-BackportTarget $state.target
    $repository = $state.repository
    $source = Get-BackportSource $repository $state.source_pr
    if ($source.merge_commit_sha -cne $state.source_sha) { throw 'Source merge identity changed.' }
    $tracking = Get-BackportTracking $repository $state.source_pr
    $batchException = $false
    if ($state.ContainsKey('batch_key')) {
        $records = @(Get-BackportBatchRecords $repository | Where-Object { $_.manifest.request.key -ceq $state.batch_key })
        if ($records.Count -ne 1) { throw 'Independent exception has no durable cohort.' }
        Assert-BackportBatchObject $records[0].issue $records[0].manifest $BotLogin
        $member = @($records[0].manifest.members | Where-Object { $_.source_pr -eq $state.source_pr })
        if ($member.Count -ne 1 -or $member[0].result.outcome -eq 'applied' -or
            (ConvertTo-BackportCanonicalJson $member[0].result) -cne (ConvertTo-BackportCanonicalJson $state.result)) {
            throw 'Independent exception differs from durable cohort.'
        }
        $batchException = $true
    }
    $clock = if ($state.ContainsKey('reference_time')) { [DateTimeOffset]$state.reference_time } else { [DateTimeOffset]::UtcNow }
    if (-not $state.manual -and $null -eq $tracking -and -not $batchException -and
        -not (Test-BackportAutomaticSource $source $clock)) { throw 'Automatic source eligibility changed before publication.' }
    $state.issues = @(Get-BackportSourceIssues $repository $state.source_pr)
    if (-not $state.manual -and $null -eq $tracking -and -not $batchException -and @($state.issues | Where-Object {
        -not (Test-BackportCategory @($_.labels.nodes | ForEach-Object { $_.name }))
    }).Count -gt 0) { throw 'A source issue is no longer automatically eligible.' }
    $state.labels = @(Get-BackportLabels -Issues $state.issues -PrLabels $source.labels)
    if ($null -ne $tracking) { Assert-BackportObject $tracking $state $BotLogin }
    $pull = Get-BackportPull $repository $state.source_pr $state.target
    if ($null -ne $pull) {
        if ($null -eq $tracking) { throw 'Existing backport PR has no tracking issue; reconcile manually.' }
        Complete-BackportPull $state $tracking $pull $BotLogin
        return
    }
    $labelsOnSource = @($source.labels | ForEach-Object { $_.name })
    if ($null -ne $tracking -and $null -ne (Read-BackportPublicationIntent $tracking.body)) {
        throw 'Previous PR creation is unconfirmed; reconcile the tracking issue publication intent before retrying.'
    }
    if (@($labelsOnSource | Where-Object { $_ -match '^ext-backport-publishing:' }).Count -gt 0) {
        throw 'Legacy PR publication is unconfirmed; operator reconciliation is required before retrying.'
    }
    if ($null -eq $tracking -and @($labelsOnSource | Where-Object { $_ -like 'ext-backport-*' }).Count -gt 0) {
        throw 'Source has prior backport state but no tracking issue. Reconcile manually; do not create a duplicate.'
    }
    if ($state.result.outcome -notin @('applied', 'conflict', 'already-present')) { throw 'No publishable preparation result.' }
    Ensure-BackportLabels $repository $state.labels
    if ($null -eq $tracking) {
        $cohorts = @(Get-BackportBatchRecords $repository | Where-Object { $state.source_pr -in $_.manifest.request.source_prs })
        if ($cohorts.Count -gt 0 -and (-not $batchException -or $cohorts[0].manifest.request.key -cne $state.batch_key)) {
            throw 'Source acquired immutable batch membership; rediscover instead of creating a Task.'
        }
        # No pre-Task journal exists. Recheck observed objects, issue exactly one POST,
        # and leave an absent/unconfirmed Task after a failed POST to the operator.
        $tracking = Get-BackportTracking $repository $state.source_pr
        $pull = Get-BackportPull $repository $state.source_pr $state.target
        if ($null -ne $tracking) {
            Assert-BackportObject $tracking $state $BotLogin
            if ($null -ne $pull) { Complete-BackportPull $state $tracking $pull $BotLogin; return }
        }
        elseif ($null -ne $pull) { throw 'Existing backport PR has no tracking issue; reconcile manually.' }
        else {
            $title = "[Backport $(($state.target -split '/')[1])] #$($state.source_pr): $($state.source_title -replace '[\r\n]', ' ')"
            if ($title.Length -gt 240) { $title = $title.Substring(0, 240) }
            $tracking = New-BackportTrackingTask $repository @{
                title = $title; body = Get-BackportBody $state; type = 'Task'
                labels = @($state.labels | ForEach-Object { $_.name })
            }
            Assert-BackportObject $tracking $state $BotLogin
        }
    }
    if ($null -ne (Read-BackportPublicationIntent $tracking.body)) {
        throw 'Previous PR creation is unconfirmed; reconcile the tracking issue publication intent before retrying.'
    }
    $retryConflict = $state.manual -and -not $batchException -and $state.result.outcome -eq 'applied' -and
        $tracking.body.Contains('Preparation result: **conflict**.')
    if (($tracking.body.Contains('Preparation result: **conflict**.') -and -not $retryConflict) -or
        $state.result.outcome -eq 'conflict') {
        Write-BackportSummary "Conflict for main PR #$($state.source_pr); manual backport tracked at $($tracking.html_url)."
        return
    }
    if ($tracking.body.Contains('Preparation result: **already-present**.') -or $state.result.outcome -eq 'already-present') {
        if ($tracking.state -ne 'closed') {
            $null = Invoke-BackportApi "repos/$repository/issues/$($tracking.number)" -Method PATCH -Body @{ state = 'closed'; state_reason = 'completed' }
        }
        Write-BackportSummary "Main PR #$($state.source_pr) is already present; closed $($tracking.html_url) without an empty PR."
        return
    }
    if ($tracking.state -eq 'closed') {
        Write-BackportSummary "Main PR #$($state.source_pr): retained closed tracking issue $($tracking.html_url); manual attention is required."
        return
    }
    $directory = Join-Path (Split-Path -Parent $StatePath) 'git'
    $head = (Invoke-BackportGit $directory @('rev-parse', 'HEAD')).text.Trim()
    $tree = (Invoke-BackportGit $directory @('rev-parse', 'HEAD^{tree}')).text.Trim()
    $parent = (Invoke-BackportGit $directory @('rev-parse', 'HEAD^')).text.Trim()
    if ($head -cne $state.result.commit -or $tree -cne $state.result.tree -or $parent -cne $state.result.target_sha) {
        throw 'Prepared Git result does not match the publication state.'
    }
    $comparison = Invoke-BackportApi "repos/$repository/compare/$parent...$($state.target)"
    if ($comparison.status -notin @('ahead', 'identical')) { throw 'Pinned release parent is no longer on the release branch.' }
    $branch = Get-BackportBranch $state.source_pr $state.target
    $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
    if ($remote) {
        if (($remote -split '\s+')[0] -cne $head) { throw 'Existing backport branch differs; never overwrite it.' }
    }
    else {
        $null = Invoke-BackportGit $directory @('push', 'origin', "$head`:refs/heads/$branch")
        $readback = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
        if (($readback -split '\s+')[0] -cne $head) { throw 'Backport branch publication was not independently confirmed.' }
    }
    $pull = Get-BackportPull $repository $state.source_pr $state.target
    if ($null -ne $pull) { Complete-BackportPull $state $tracking $pull $BotLogin; return }
    if ($retryConflict) {
        $null = Invoke-BackportApi "repos/$repository/issues/$($tracking.number)" -Method PATCH -Body @{
            body = Get-BackportBody $state
        }
        $tracking = Invoke-BackportApi "repos/$repository/issues/$($tracking.number)"
        Assert-BackportObject $tracking $state $BotLogin
    }
    $tracking = Set-BackportPublicationIntent $state $tracking $head $BotLogin
    $title = "[Backport $(($state.target -split '/')[1])] #$($state.source_pr): $($state.source_title -replace '[\r\n]', ' ')"
    if ($title.Length -gt 240) { $title = $title.Substring(0, 240) }
    $pull = Invoke-BackportApi "repos/$repository/pulls" -Method POST -Body @{
        title = $title; body = Get-BackportBody $state $tracking.number
        head = $branch; base = $state.target; draft = $true
    }
    $pull = Invoke-BackportApi "repos/$repository/pulls/$($pull.number)"
    Assert-BackportObject $pull $state $BotLogin
    if ($pull.head.sha -cne $head) { throw 'Created backport PR does not contain the prepared commit.' }
    Complete-BackportPull $state $tracking $pull $BotLogin
}

function ConvertTo-BackportCanonicalJson {
    param($Value)
    function Convert-Value($Item) {
        # ConvertFrom-Json versions differ in whether ISO timestamps stay strings.
        if ($Item -is [datetime] -or $Item -is [DateTimeOffset] -or
            ($Item -is [string] -and $Item -match '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)$')) {
            return ([DateTimeOffset]$Item).UtcDateTime.ToString('o')
        }
        if ($Item -is [Collections.IDictionary]) {
            $sorted = [ordered]@{}
            foreach ($key in @($Item.Keys | Sort-Object -CaseSensitive)) { $sorted[$key] = Convert-Value $Item[$key] }
            return $sorted
        }
        if ($Item -is [array]) { return ,@($Item | ForEach-Object { Convert-Value $_ }) }
        return $Item
    }
    ConvertTo-Json -InputObject (Convert-Value $Value) -Depth 60 -Compress
}

function Get-BackportDigest {
    param([string] $Text)
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}

function Assert-BackportBatchRequest {
    param([hashtable] $Request)
    foreach ($name in @('key', 'mode', 'source_prs', 'sources', 'target', 'team', 'batch_id', 'reference_time', 'manual')) {
        if (-not $Request.ContainsKey($name)) { throw "Missing batch request field $name." }
    }
    Assert-BackportTarget $Request.target
    if ($Request.key -cnotmatch '^(team-[0-9a-f]{32}|single-[1-9][0-9]*)$' -or
        $Request.mode -notin @('team', 'single') -or $Request.batch_id -cnotmatch '^[0-9]+$' -or
        $Request.manual -isnot [bool] -or
        ($Request.reference_time -isnot [datetime] -and
            ([DateTimeOffset]$Request.reference_time).Offset -ne [TimeSpan]::Zero)) {
        throw 'Invalid batch request identity or discovery clock.'
    }
    $numbers = @($Request.source_prs)
    if ($numbers.Count -eq 0 -or $numbers.Count -gt 256 -or
        @($numbers | Sort-Object -Unique).Count -ne $numbers.Count -or
        @($Request.sources).Count -ne $numbers.Count) { throw 'Invalid or duplicate batch membership.' }
    for ($i = 0; $i -lt $numbers.Count; $i++) {
        $proof = $Request.sources[$i]
        if ([string]$numbers[$i] -cnotmatch '^[1-9][0-9]*$' -or $proof.number -ne $numbers[$i] -or
            $proof.sha -cnotmatch '^[0-9a-f]{40}$') { throw 'Invalid source proof in batch membership.' }
        $null = [DateTimeOffset]$proof.merged_at
    }
    $chronological = @($Request.sources | Sort-Object { [DateTimeOffset]$_.merged_at }, number | ForEach-Object { $_.number })
    if (($chronological -join ',') -cne ($numbers -join ',')) { throw 'Batch sources must be oldest first.' }
    if ($Request.mode -eq 'single') {
        if ($numbers.Count -ne 1 -or $Request.key -cne "single-$($numbers[0])") { throw 'Invalid independent request.' }
    }
    else {
        if ($Request.team -cnotmatch '^Team: \S[^\r\n]*$' -or $Request.manual) { throw 'Invalid team request.' }
        $identity = @{} + $Request
        [void]$identity.Remove('key')
        [void]$identity.Remove('manifest')
        $expected = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $identity)).Substring(0, 32)
        if ($Request.key -cne $expected) { throw 'Batch membership or identity has changed.' }
    }
}

function Get-BackportBatchMarker {
    param([hashtable] $Manifest)
    $json = ConvertTo-BackportCanonicalJson $Manifest
    "<!-- bc-extrequest-backport:v2 $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))) -->"
}

function Read-BackportBatchMarker {
    param([string] $Body)
    $markers = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:v2 ([A-Za-z0-9+/=]+) -->\r?$')
    if ($markers.Count -gt 1) { throw 'Multiple batch manifests on one object.' }
    if ($markers.Count -eq 0) {
        if ($Body.Contains('bc-extrequest-backport:v2')) { throw 'Malformed batch manifest.' }
        return $null
    }
    $manifest = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($markers[0].Groups[1].Value)) |
        ConvertFrom-Json -AsHashtable -Depth 60
    Assert-BackportBatchManifest $manifest
    return $manifest
}

function Assert-BackportBatchManifest {
    param([hashtable] $Manifest)
    if ($Manifest.schema -ne 2) { throw 'Unsupported batch manifest schema.' }
    Assert-BackportRepository $Manifest.repository
    Assert-BackportBatchRequest $Manifest.request
    if ($Manifest.request.mode -ne 'team' -or $Manifest.request.ContainsKey('manifest') -or
        @($Manifest.members).Count -ne @($Manifest.request.source_prs).Count -or
        $Manifest.target_sha -cnotmatch '^[0-9a-f]{40}$') { throw 'Invalid complete batch manifest.' }
    $tip = $Manifest.target_sha
    for ($i = 0; $i -lt $Manifest.members.Count; $i++) {
        $member = $Manifest.members[$i]
        $proof = $Manifest.request.sources[$i]
        if ($member.schema -ne 1 -or $member.repository -cne $Manifest.repository -or
            $member.target -cne $Manifest.request.target -or $member.source_pr -ne $proof.number -or
            $member.source_sha -cne $proof.sha -or
            $member.result.outcome -notin @('applied', 'conflict', 'already-present') -or
            $member.result.target_sha -cne $tip) { throw 'Invalid batch member or cumulative parent.' }
        if ($member.result.outcome -eq 'applied') {
            if ($member.result.commit -cnotmatch '^[0-9a-f]{40}$' -or
                $member.result.tree -cnotmatch '^[0-9a-f]{40}$') { throw 'Invalid prepared batch commit.' }
            $tip = $member.result.commit
        }
    }
    $applied = @($Manifest.members | Where-Object { $_.result.outcome -eq 'applied' })
    if ($Manifest.head -cne $tip -or
        ($applied.Count -gt 0 -and $Manifest.tree -cne $applied[-1].result.tree)) { throw 'Invalid batch tip or tree.' }
}

function Get-BackportBatchRecords {
    param([string] $Repository)
    $mapping = @{}
    foreach ($issue in @(Get-BackportApiPages "repos/$Repository/issues?state=all&labels=ext-backporting")) {
        if ($issue.ContainsKey('pull_request')) { continue }
        $manifest = Read-BackportBatchMarker $issue.body
        if ($null -eq $manifest) { continue }
        foreach ($number in $manifest.request.source_prs) {
            if ($mapping.ContainsKey([string]$number)) { throw "Multiple batch mappings for source #$number." }
            $mapping[[string]$number] = $manifest.request.key
        }
        @{ issue = $issue; manifest = $manifest }
    }
}

function Get-BackportBatchPull {
    param([string] $Repository, [string] $Key)
    $owner = $Repository.Split('/')[0]
    $pulls = @(Get-BackportApiPages "repos/$Repository/pulls?state=all&head=$owner`:bc-extrequest-backport/$Key")
    if ($pulls.Count -gt 1) { throw 'Multiple PRs for one batch branch.' }
    if ($pulls.Count -eq 1) { return $pulls[0] }
    return $null
}

function Get-BackportSourceTeam {
    param([hashtable] $Source, [object[]] $Issues, [string] $Repository)
    $teams = @($Source.labels | ForEach-Object { $_.name } | Where-Object { $_ -clike 'Team: *' })
    if ($teams.Count -ne 1 -or $teams[0] -cnotmatch '^Team: \S[^\r\n]*$') { return '' }
    foreach ($issue in $Issues) {
        $issueTeams = @($issue.labels.nodes | ForEach-Object { $_.name } | Where-Object { $_ -clike 'Team: *' })
        if ($issueTeams.Count -ne 1 -or $issueTeams[0] -cne $teams[0] -or
            -not $issue.ContainsKey('repository') -or $null -eq $issue.repository -or
            -not $issue.repository.ContainsKey('nameWithOwner') -or $issue.repository.nameWithOwner -cne $Repository) { return '' }
    }
    return $teams[0]
}

function Find-ExtRequestBackportBatches {
    [CmdletBinding()]
    param([string] $Repository, [string] $SourcePr = '', [string] $TargetOverride = '', [string] $BatchId)
    Assert-BackportRepository $Repository
    if ($BatchId -cnotmatch '^[0-9]+$') { throw 'BatchId must be the numeric GitHub run_id.' }
    $clock = [DateTimeOffset]::UtcNow.ToString('o')
    $records = @(Get-BackportBatchRecords $Repository)
    $mapped = @{}
    $requests = @{}
    foreach ($record in $records) {
        foreach ($number in $record.manifest.request.source_prs) { $mapped[[string]$number] = $record }
    }
    if ($SourcePr) {
        if ($SourcePr -cnotmatch '^[1-9][0-9]{0,9}$') { throw 'source_pr must be a positive PR number.' }
        if ($mapped.ContainsKey($SourcePr)) {
            $row = @{} + $mapped[$SourcePr].manifest.request
            $row.manifest = $mapped[$SourcePr].manifest
            return $row
        }
    }
    $candidates = @(Find-ExtRequestBackport $Repository -SourcePr $SourcePr -TargetOverride $TargetOverride -ReferenceTime ([DateTimeOffset]$clock))
    # A durable cohort survives the discovery window. Completed sources need no
    # lifecycle polling; resume only missing processed flags or independent records.
    if (-not $SourcePr) {
        foreach ($record in $records) {
            $unfinished = $false
            foreach ($member in $record.manifest.members) {
                if ($member.result.outcome -eq 'applied') {
                    $original = Get-BackportSource $Repository $member.source_pr
                    if ('ext-backport-processed' -notin @($original.labels | ForEach-Object { $_.name })) { $unfinished = $true }
                }
                else {
                    $independent = Get-BackportTracking $Repository $member.source_pr
                    if ($null -eq $independent -or ($member.result.outcome -eq 'already-present' -and $independent.state -ne 'closed')) {
                        $unfinished = $true
                    }
                }
            }
            if ($unfinished) {
                $row = @{} + $record.manifest.request
                $row.manifest = $record.manifest
                $requests[$row.key] = $row
            }
        }
    }
    $groups = @{}
    foreach ($candidate in $candidates) {
        $number = [long]$candidate.source_pr
        if ($mapped.ContainsKey([string]$number)) { continue }
        $source = Get-BackportSource $Repository $number
        $issues = @(Get-BackportSourceIssues $Repository $number)
        if (-not $SourcePr -and @($issues | Where-Object {
            -not (Test-BackportCategory @($_.labels.nodes | ForEach-Object { $_.name }))
        }).Count -gt 0) { continue }
        $tracking = Get-BackportTracking $Repository $number
        $target = Get-BackportPinnedTarget $source $tracking $candidate.target
        $team = Get-BackportSourceTeam $source $issues $Repository
        $prior = @($source.labels | Where-Object { $_.name -like 'ext-backport-*' }).Count -gt 0
        $mode = if ($SourcePr -or $null -ne $tracking -or $prior -or -not $team) { 'single' } else { 'team' }
        $group = if ($mode -eq 'single') { "single-$number" } else { "$team|$target" }
        if (-not $groups.ContainsKey($group)) {
            $groups[$group] = @{
                mode = $mode; team = $team; target = $target; batch_id = $BatchId
                reference_time = $clock; manual = [bool]$SourcePr; sources = @()
            }
        }
        $groups[$group].sources += @{ number = $number; sha = $source.merge_commit_sha; merged_at = $source.merged_at }
    }
    foreach ($row in $groups.Values) {
        $row.sources = @($row.sources | Sort-Object { [DateTimeOffset]$_.merged_at }, number)
        $row.source_prs = @($row.sources | ForEach-Object { $_.number })
        $row.concurrency_key = if ($row.team) {
            'team-' + (Get-BackportDigest "$($row.team)|$($row.target)").Substring(0, 24)
        } else { "single-$($row.source_prs[0])" }
        $row.key = if ($row.mode -eq 'single') { "single-$($row.source_prs[0])" }
            else { 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $row)).Substring(0, 32) }
        Assert-BackportBatchRequest $row
        $requests[$row.key] = $row
    }
    if ($requests.Count -gt 256) { throw 'More than 256 requests including resumable batches; reconcile existing work first.' }
    foreach ($key in @($requests.Keys | Sort-Object)) { $requests[$key] }
}

function Initialize-BackportBatchGit {
    param([string] $Directory, [string] $Repository)
    if (Test-Path -LiteralPath $Directory) { throw 'Backport work directory already exists.' }
    $null = New-Item -ItemType Directory -Path $Directory -Force
    $null = Invoke-BackportGit $Directory @('init', '--quiet')
    [IO.File]::WriteAllText((Join-Path $Directory '.git/empty-config'), '')
    [IO.File]::WriteAllText((Join-Path $Directory '.git/info/attributes'),
        "* -filter -ident -text !eol !working-tree-encoding !merge`n")
    $null = Invoke-BackportGit $Directory @('remote', 'add', 'origin', "https://github.com/$Repository.git")
}

function Invoke-BackportBatchApply {
    param([string] $Directory, [string] $SourceSha, [string] $Tip, [string] $ReleaseSha, [string[]] $BlockedPaths)
    $result = Invoke-BackportApply $Directory $SourceSha $Tip -BlockedPaths $BlockedPaths
    if ($result.outcome -eq 'already-present' -and $Tip -cne $ReleaseSha) {
        $baseline = Invoke-BackportApply $Directory $SourceSha $ReleaseSha
        $null = Invoke-BackportGit $Directory @('checkout', '--detach', $Tip)
        # A patch present only on an unmerged batch tip is not a completed release no-op.
        if ($baseline.outcome -ne 'already-present') {
            $result.outcome = 'conflict'
            $result.tree = $null
        }
    }
    return $result
}

function Assert-BackportBatchSources {
    param([hashtable] $Request, [string] $Repository, [switch] $Resume)
    foreach ($proof in $Request.sources) {
        $source = Get-BackportSource $Repository $proof.number
        if ($source.merge_commit_sha -cne $proof.sha) { throw 'Batch source SHA changed.' }
        if (([DateTimeOffset]$source.merged_at) -ne ([DateTimeOffset]$proof.merged_at)) { throw 'Batch merge metadata changed.' }
        if ((Get-BackportPinnedTarget $source $null $Request.target) -cne $Request.target) {
            throw 'Batch source has a different pinned target.'
        }
        $issues = @(Get-BackportSourceIssues $Repository $proof.number)
        if (-not $Request.manual -and -not $Resume) {
            if (-not (Test-BackportAutomaticSource $source ([DateTimeOffset]$Request.reference_time)) -or
                @($issues | Where-Object {
                    -not (Test-BackportCategory @($_.labels.nodes | ForEach-Object { $_.name }))
                }).Count -gt 0) { throw 'Batch source or original issue eligibility changed.' }
            if ($Request.mode -eq 'team' -and
                (Get-BackportSourceTeam $source $issues $Repository) -cne $Request.team) { throw 'Batch team metadata changed.' }
        }
        @{ source = $source; issues = $issues }
    }
}

function New-ExtRequestBackportBatch {
    [CmdletBinding()]
    param([string] $Repository, [string] $RequestJson, [string] $StatePath)
    Assert-BackportRepository $Repository
    if (-not [IO.Path]::IsPathFullyQualified($StatePath)) { throw 'StatePath must be absolute.' }
    $request = ConvertFrom-Json $RequestJson -AsHashtable -Depth 60
    Assert-BackportBatchRequest $request
    $records = @(Get-BackportBatchRecords $Repository)
    $overlap = @($records | Where-Object {
        @($_.manifest.request.source_prs | Where-Object { $_ -in $request.source_prs }).Count -gt 0
    })
    if ($overlap.Count -gt 1) { throw 'Request overlaps multiple immutable batches.' }
    $resume = $overlap.Count -eq 1
    if ($resume) {
        $stored = $overlap[0].manifest
        $identity = @{} + $request
        [void]$identity.Remove('manifest')
        if ($stored.request.key -cne $request.key -or
            (ConvertTo-BackportCanonicalJson $stored.request) -cne (ConvertTo-BackportCanonicalJson $identity)) {
            throw 'Request differs from the existing immutable batch; rediscover it.'
        }
        $request = $stored.request
    }
    elseif ($request.ContainsKey('manifest')) { throw 'Previously discovered batch tracking issue is missing.' }
    $metadata = @(Assert-BackportBatchSources $request $Repository -Resume:$resume)
    $root = Split-Path -Parent $StatePath
    $null = New-Item -ItemType Directory -Path $root -Force
    if ($request.mode -eq 'single') {
        New-ExtRequestBackport $Repository $request.source_prs[0] $request.target $request.manual $StatePath `
            -ReferenceTime ([DateTimeOffset]$request.reference_time)
        $single = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -AsHashtable -Depth 60
        if ($single.schema -eq 1 -and $single.source_sha -cne $request.sources[0].sha) {
            throw 'Independent source proof changed during preparation.'
        }
        return
    }
    if ($resume -and ($null -ne (Get-BackportBatchPull $Repository $request.key) -or
        $null -ne (Read-BackportPublicationIntent $overlap[0].issue.body))) {
        $stored | ConvertTo-Json -Depth 60 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
        Write-BackportBatchSummary $stored 'prepared'
        return
    }
    if (-not $resume) {
        foreach ($item in $metadata) {
            $tracking = Get-BackportTracking $Repository $item.source.number
            $prior = @($item.source.labels | Where-Object { $_.name -like 'ext-backport-*' })
            if ($null -ne $tracking -or $prior.Count -gt 0) { throw 'Source acquired independent state; rediscover, never re-batch it.' }
        }
    }
    $directory = Join-Path $root 'git'
    Initialize-BackportBatchGit $directory $Repository
    $targetSha = if ($resume) { $stored.target_sha }
        else { (Invoke-BackportApi "repos/$Repository/git/ref/heads/$($request.target)").object.sha }
    $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/bc-extrequest-backport/$($request.key)")).text.Trim()
    if ($remote -and -not $resume) { throw 'Untracked batch branch exists; reconcile manually.' }
    $null = Invoke-BackportGit $directory @('fetch', '--quiet', '--no-tags', '--filter=blob:none', '--depth=2',
        'origin', "$targetSha`:refs/backport/target")
    $tip = $targetSha
    $members = @()
    $blocked = @()
    for ($i = 0; $i -lt $request.sources.Count; $i++) {
        $proof = $request.sources[$i]
        $comparison = Invoke-BackportApi "repos/$Repository/compare/$($proof.sha)...main"
        if ($comparison.status -notin @('ahead', 'identical')) { throw 'Batch source is not on main.' }
        $null = Invoke-BackportGit $directory @('fetch', '--quiet', '--no-tags', '--filter=blob:none', '--depth=2',
            'origin', "$($proof.sha):refs/backport/source-$($proof.number)")
        $result = Invoke-BackportBatchApply $directory $proof.sha $tip $targetSha $blocked
        if ($result.outcome -eq 'conflict') { $blocked += $result.paths }
        $members += @{
            schema = 1; repository = $Repository; source_pr = $proof.number; source_sha = $proof.sha
            target = $request.target; manual = $request.manual; reference_time = $request.reference_time
            source_title = $metadata[$i].source.title; issues = $metadata[$i].issues
            labels = @(Get-BackportLabels $metadata[$i].issues $metadata[$i].source.labels); result = $result
        }
        if ($result.outcome -eq 'applied') { $tip = $result.commit }
    }
    $manifest = @{
        schema = 2; repository = $Repository; request = $request; members = $members; target_sha = $targetSha
        head = $tip; tree = (Invoke-BackportGit $directory @('rev-parse', "$tip`^{tree}")).text.Trim()
    }
    if ($resume) {
        # Membership, outcomes, source proofs and commit chain cannot change during recovery.
        foreach ($index in 0..($members.Count - 1)) {
            if ((ConvertTo-BackportCanonicalJson $members[$index].result) -cne
                (ConvertTo-BackportCanonicalJson $stored.members[$index].result)) { throw 'Prepared batch differs from durable results.' }
        }
        $manifest = $stored
    }
    if ($remote -and ($remote -split '\s+')[0] -cne $manifest.head) { throw 'Existing batch branch differs; never overwrite it.' }
    Assert-BackportBatchManifest $manifest
    if (@($members | Where-Object { $_.result.outcome -eq 'applied' }).Count -gt 0) {
        $null = Get-BackportBatchBody $manifest 9999999999
    }
    $manifest | ConvertTo-Json -Depth 60 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
    Write-BackportBatchSummary $manifest 'prepared'
}

function Get-BackportBatchLabels {
    param([hashtable] $Manifest)
    $labels = @{}
    foreach ($member in @($Manifest.members | Where-Object { $_.result.outcome -eq 'applied' })) {
        foreach ($label in $member.labels) { $labels[$label.name] = $label }
    }
    @($labels.Values | Sort-Object name)
}

function Get-BackportBatchBody {
    param([hashtable] $Manifest, [long] $TrackingNumber = 0)
    $lines = @((Get-BackportBatchMarker $Manifest), '',
        "Team: $($Manifest.request.team). Target: ``$($Manifest.request.target)``.", '', '## Included main PRs')
    $issues = @{}
    foreach ($member in $Manifest.members) {
        if ($member.result.outcome -ne 'applied') { continue }
        $lines += "- https://github.com/$($Manifest.repository)/pull/$($member.source_pr) - source ``$($member.source_sha)``"
        foreach ($issue in $member.issues) { $issues[$issue.url] = $issue }
    }
    $lines += @('', '## Original main issues')
    foreach ($url in @($issues.Keys | Sort-Object)) { $lines += "- $url" }
    $lines += @('', '## Independent outcomes')
    foreach ($member in $Manifest.members) {
        if ($member.result.outcome -ne 'applied') { $lines += "- Main PR #$($member.source_pr): $($member.result.outcome); tracked independently." }
    }
    if ($TrackingNumber -gt 0) { $lines += @('', "Backport tracking issue: https://github.com/$($Manifest.repository)/issues/$TrackingNumber") }
    $lines += @('', 'Review the cumulative change and run normal release CI. No AI resolver was used.')
    $body = $lines -join "`n"
    if ($body.Length -gt 65000) { throw 'Complete batch manifest exceeds GitHub body limits; reduce the cohort, never truncate membership.' }
    return $body
}

function Write-BackportBatchSummary {
    param([hashtable] $Manifest, [string] $Status, [string] $Urls = '')
    $applied = @($Manifest.members | Where-Object { $_.result.outcome -eq 'applied' }).Count
    $conflicts = @($Manifest.members | Where-Object { $_.result.outcome -eq 'conflict' }).Count
    $present = @($Manifest.members | Where-Object { $_.result.outcome -eq 'already-present' }).Count
    Write-BackportSummary "Main PRs #$($Manifest.request.source_prs -join ', #'); $($Manifest.request.team) -> $($Manifest.request.target): **$Status**. Included: $applied; conflicted: $conflicts; already-present: $present. $Urls"
    if ($Status -eq 'prepared') {
        foreach ($member in $Manifest.members) {
            $issues = if ($member.issues.Count -gt 0) {
                (@($member.issues | ForEach-Object { $_.url } | Sort-Object -Unique)) -join ', '
            } else { '(none)' }
            Write-BackportSummary "- Main PR https://github.com/$($Manifest.repository)/pull/$($member.source_pr); $($Manifest.request.team); target ``$($Manifest.request.target)``; source ``$($member.source_sha)``; outcome **$($member.result.outcome)**; original issues: $issues"
        }
    }
}

function Assert-BackportBatchObject {
    param([hashtable] $Object, [hashtable] $Manifest, [string] $BotLogin)
    $found = Read-BackportBatchMarker $Object.body
    if ($null -eq $found -or $Object.user.login -cne $BotLogin -or
        (Get-BackportBatchMarker $found) -cne (Get-BackportBatchMarker $Manifest)) {
        throw 'Batch object has an unexpected author or immutable manifest.'
    }
    if ($Object.ContainsKey('head') -and
        ($Object.head.ref -cne "bc-extrequest-backport/$($Manifest.request.key)" -or
        $Object.head.sha -cne $Manifest.head -or $Object.head.repo.full_name -cne $Manifest.repository -or
        $Object.base.ref -cne $Manifest.request.target -or $Object.base.repo.full_name -cne $Manifest.repository)) {
        throw 'Batch PR branch, target or provenance changed; never adopt human changes.'
    }
}

function Complete-BackportBatchPull {
    param([hashtable] $Manifest, [hashtable] $Tracking, [hashtable] $Pull, [string] $BotLogin)
    Assert-BackportBatchObject $Tracking $Manifest $BotLogin
    Assert-BackportBatchObject $Pull $Manifest $BotLogin
    if (-not $Pull.ContainsKey('head')) { throw 'The batch result is not a validated backport PR.' }
    # Reconciliation verifies every source identity, including already processed members.
    $null = @(Assert-BackportBatchSources $Manifest.request $Manifest.repository -Resume)
    $labels = @(Get-BackportBatchLabels $Manifest)
    Ensure-BackportLabels $Manifest.repository $labels
    foreach ($number in @($Tracking.number, $Pull.number)) {
        $null = Invoke-BackportApi "repos/$($Manifest.repository)/issues/$number/labels" -Method POST -Body @{
            labels = @($labels | ForEach-Object { $_.name })
        }
    }
    $link = "Backport PR: $($Pull.html_url)"
    if (-not $Tracking.body.Contains($link)) {
        $null = Invoke-BackportApi "repos/$($Manifest.repository)/issues/$($Tracking.number)" -Method PATCH -Body @{ body = "$($Tracking.body)`n`n$link" }
    }
    foreach ($member in $Manifest.members) {
        if ($member.result.outcome -ne 'applied') { continue }
        Set-BackportProcessed $Manifest.repository $member.source_pr
    }
    Write-BackportBatchSummary $Manifest 'validated PR' "$($Tracking.html_url) $($Pull.html_url)"
}

function Publish-BackportBatchExceptions {
    param([hashtable] $Manifest, [string] $BotLogin, [switch] $Durable, [switch] $ContinueOnFailure)
    foreach ($member in $Manifest.members) {
        if ($member.result.outcome -eq 'applied') { continue }
        # Preserve the proven cumulative-tip outcome. A release-only reapplication can
        # succeed while conflicting with the clean team changes, so never re-prepare here.
        $single = @{} + $member
        if ($Durable) { $single.batch_key = $Manifest.request.key }
        try { Publish-ExtRequestBackport -BotLogin $BotLogin -PreparedState $single }
        catch {
            if (-not $ContinueOnFailure) { throw }
            $failure = "Independent source #$($member.source_pr): $($_.Exception.Message)"
            Write-Warning $failure
            $failure
        }
    }
}

function Assert-BackportPreparedBatch {
    param([hashtable] $Manifest, [string] $Directory)
    $tip = $Manifest.target_sha
    $blocked = @()
    foreach ($member in $Manifest.members) {
        $result = Invoke-BackportBatchApply $Directory $member.source_sha $tip $Manifest.target_sha $blocked
        if ($result.outcome -eq 'conflict') { $blocked += $result.paths }
        if ((ConvertTo-BackportCanonicalJson $result) -cne (ConvertTo-BackportCanonicalJson $member.result)) {
            throw 'Prepared result/source provenance differs from immutable batch state.'
        }
        if ($result.outcome -eq 'applied') { $tip = $result.commit }
    }
    $null = Invoke-BackportGit $Directory @('checkout', '--detach', $tip)
    $tree = (Invoke-BackportGit $Directory @('rev-parse', 'HEAD^{tree}')).text.Trim()
    if ($tip -cne $Manifest.head -or $tree -cne $Manifest.tree) { throw 'Prepared cumulative tree changed.' }
    $comparison = Invoke-BackportApi "repos/$($Manifest.repository)/compare/$($Manifest.target_sha)...$($Manifest.request.target)"
    if ($comparison.status -notin @('ahead', 'identical')) { throw 'Pinned batch parent is no longer on release.' }
}

function Publish-ExtRequestBackportBatch {
    [CmdletBinding()]
    param([string] $StatePath, [string] $BotLogin)
    $manifest = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -AsHashtable -Depth 60
    if ($manifest.schema -eq 1) { Publish-ExtRequestBackport $StatePath $BotLogin; return }
    if ($BotLogin -cnotmatch '^[a-z0-9-]+\[bot\]$') { throw 'Invalid App identity.' }
    Assert-BackportBatchManifest $manifest
    $null = Get-BackportBatchBody $manifest 9999999999
    $request = $manifest.request
    $repository = $manifest.repository
    $records = @(Get-BackportBatchRecords $repository)
    $overlap = @($records | Where-Object {
        @($_.manifest.request.source_prs | Where-Object { $_ -in $request.source_prs }).Count -gt 0
    })
    if ($overlap.Count -gt 1) { throw 'Multiple durable batch mappings.' }
    $tracking = if ($overlap.Count -eq 1) { $overlap[0].issue } else { $null }
    if ($null -ne $tracking) { Assert-BackportBatchObject $tracking $manifest $BotLogin }
    $metadata = @(Assert-BackportBatchSources $request $repository -Resume:($null -ne $tracking))
    $directory = Join-Path (Split-Path -Parent $StatePath) 'git'
    $applied = @($manifest.members | Where-Object { $_.result.outcome -eq 'applied' })
    $exceptionFailures = @()
    $pull = Get-BackportBatchPull $repository $request.key
    if ($null -ne $pull -and $null -eq $tracking) { throw 'Batch PR has no tracking issue.' }
    if ($null -ne $pull) {
        Assert-BackportBatchObject $pull $manifest $BotLogin
        $exceptionFailures = @(Publish-BackportBatchExceptions $manifest $BotLogin -Durable -ContinueOnFailure)
        Complete-BackportBatchPull $manifest $tracking $pull $BotLogin
        if ($exceptionFailures.Count -gt 0) { throw ($exceptionFailures -join "`n") }
        return
    }
    if ($null -ne $tracking -and $null -ne (Read-BackportPublicationIntent $tracking.body)) {
        throw 'Previous batch PR creation is unconfirmed; reconcile the tracking issue publication intent before retrying.'
    }
    if (@($metadata | ForEach-Object { $_.source.labels } | Where-Object {
        $_.name -match '^ext-backport-publishing:'
    }).Count -gt 0) { throw 'Legacy batch PR publication is unconfirmed; operator reconciliation is required before retrying.' }
    Assert-BackportPreparedBatch $manifest $directory
    if ($applied.Count -gt 0) {
        $labels = @(Get-BackportBatchLabels $manifest)
        Ensure-BackportLabels $repository $labels
        if ($null -eq $tracking) {
            $observed = @(Get-BackportBatchRecords $repository | Where-Object {
                @($_.manifest.request.source_prs | Where-Object { $_ -in $request.source_prs }).Count -gt 0
            })
            if ($observed.Count -gt 1) { throw 'Multiple durable batch mappings.' }
            if ($observed.Count -eq 1) {
                $tracking = $observed[0].issue
                Assert-BackportBatchObject $tracking $manifest $BotLogin
            }
            else {
                foreach ($item in @(Assert-BackportBatchSources $request $repository)) {
                    if ($null -ne (Get-BackportTracking $repository $item.source.number) -or
                        @($item.source.labels | Where-Object { $_.name -like 'ext-backport-*' }).Count -gt 0) {
                        throw 'Source has prior backport state; do not create a duplicate batch.'
                    }
                }
                $pull = Get-BackportBatchPull $repository $request.key
                if ($null -ne $pull) { throw 'Batch PR has no tracking issue.' }
                # One creation attempt only. Without a pre-Task journal, an absent Task
                # after a failed POST is uncertain and requires operator investigation.
                $tracking = New-BackportTrackingTask $repository @{
                    title = "[Backport $(($request.target -split '/')[1])] $($request.team) - $($request.key)"
                    body = Get-BackportBatchBody $manifest; type = 'Task'; labels = @($labels | ForEach-Object { $_.name })
                }
                Assert-BackportBatchObject $tracking $manifest $BotLogin
            }
        }
        $exceptionFailures = @(Publish-BackportBatchExceptions $manifest $BotLogin -Durable -ContinueOnFailure)
        $pull = Get-BackportBatchPull $repository $request.key
        if ($null -ne $pull) { Complete-BackportBatchPull $manifest $tracking $pull $BotLogin }
        elseif ($tracking.state -eq 'closed') {
            throw 'Closed batch issue has no PR; manual reconciliation required.'
        }
        else {
            if ($null -ne (Read-BackportPublicationIntent $tracking.body)) {
                throw 'Previous batch PR creation is unconfirmed; reconcile the tracking issue publication intent before retrying.'
            }
            $branch = "bc-extrequest-backport/$($request.key)"
            $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
            if ($remote) {
                if (($remote -split '\s+')[0] -cne $manifest.head) { throw 'Existing batch branch differs; never overwrite it.' }
            }
            else {
                $null = Invoke-BackportGit $directory @('push', 'origin', "$($manifest.head):refs/heads/$branch")
                $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
                if (($remote -split '\s+')[0] -cne $manifest.head) { throw 'Batch branch publication not confirmed.' }
            }
            $tracking = Set-BackportPublicationIntent $manifest $tracking $manifest.head $BotLogin
            $pull = Invoke-BackportApi "repos/$repository/pulls" -Method POST -Body @{
                title = "[Backport $(($request.target -split '/')[1])] $($request.team) - $($request.key)"
                body = Get-BackportBatchBody $manifest $tracking.number; head = $branch; base = $request.target; draft = $true
            }
            $pull = Invoke-BackportApi "repos/$repository/pulls/$($pull.number)"
            Complete-BackportBatchPull $manifest $tracking $pull $BotLogin
        }
    }
    if ($applied.Count -eq 0) { $exceptionFailures = @(Publish-BackportBatchExceptions $manifest $BotLogin -ContinueOnFailure) }
    $summaryStatus = if ($exceptionFailures.Count -gt 0) { 'partial publication - independent outcomes need attention' } else { 'published' }
    Write-BackportBatchSummary $manifest $summaryStatus
    if ($exceptionFailures.Count -gt 0) { throw ($exceptionFailures -join "`n") }
}

Export-ModuleMember -Function Find-ExtRequestBackport, New-ExtRequestBackport, Publish-ExtRequestBackport,
    Find-ExtRequestBackportBatches, New-ExtRequestBackportBatch, Publish-ExtRequestBackportBatch
