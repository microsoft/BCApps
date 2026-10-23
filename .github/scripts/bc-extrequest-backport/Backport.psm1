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
    $markerMatches = [regex]::Matches($Body,
        '(?m)^<!-- bc-extrequest-backport:v1 source=([1-9][0-9]*) target=(releases/[1-9][0-9]*\.x) sha=([0-9a-f]{40}) -->\r?$')
    if ($markerMatches.Count -gt 1) { throw 'Multiple backport identities on one object.' }
    if ($markerMatches.Count -eq 0) { return $null }
    return @{ source_pr = [long]$markerMatches[0].Groups[1].Value; target = $markerMatches[0].Groups[2].Value; sha = $markerMatches[0].Groups[3].Value }
}

function Get-BackportTracking {
    param([string] $Repository, [long] $SourcePr)

    $trackingIssues = @(Get-BackportApiPages "repos/$Repository/issues?state=all&labels=ext-backporting" |
        Where-Object {
            if ($_.ContainsKey('pull_request')) { return $false }
            $batch = Read-BackportBatchMarker $_.body
            if ($null -ne $batch -and @($batch.members | Where-Object {
                $_.source_pr -eq $SourcePr -and $_.result.outcome -eq 'applied'
            }).Count -gt 0) { throw "Source #$SourcePr belongs to batch $($batch.request.key); use the batch API to reconcile it." }
            $marker = Read-BackportMarker $_.body
            return $null -ne $marker -and $marker.source_pr -eq $SourcePr
        })
    if ($trackingIssues.Count -gt 1) { throw "Multiple tracking issues for source PR #$SourcePr; reconcile manually." }
    if ($trackingIssues.Count -eq 1) { return $trackingIssues[0] }
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

function Publish-BackportBranchCreateOnly {
    param([string] $Directory, [string] $Branch, [string] $Head)
    # An empty lease cannot change an existing ref; identical heads may succeed as a no-op, not ownership proof.
    $null = Invoke-BackportGit $Directory @('push', "--force-with-lease=refs/heads/$($Branch):",
        'origin', "$($Head):refs/heads/$Branch")
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
        $row = Get-BackportResumeRequest $batch[0] -Manual:$Manual
        New-ExtRequestBackportBatch $Repository (ConvertTo-Json $row -Depth 60) $StatePath
        return
    }
    $source = Get-BackportSource $Repository $SourcePr
    $issues = @(Get-BackportSourceIssues $Repository $SourcePr)
    $labels = @(Get-BackportLabels -Issues $issues -PrLabels $source.labels)
    $tracking = Get-BackportTracking $Repository $SourcePr
    if ($null -eq $tracking) {
        $request = @{
            mode = 'single'; key = "single-$SourcePr"; source_prs = @($SourcePr)
            sources = @(@{ number = $SourcePr; sha = $source.merge_commit_sha; merged_at = $source.merged_at })
            target = $Target; team = Get-BackportSourceTeam $source $issues $Repository
            batch_id = '0'; reference_time = $ReferenceTime.ToUniversalTime().ToString('o'); manual = $Manual
            release = Get-BackportRelease $Repository $Target
        }
        New-ExtRequestBackportBatch $Repository (ConvertTo-Json $request -Depth 60) $StatePath
        return
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
    $pinnedRelease = if ($null -eq $pull -and $result.outcome -eq 'existing' -and -not $publicationBlocked) {
        Get-BackportRelease $Repository $target
    } else { $null }
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
    if ($null -ne $pinnedRelease) {
        Assert-BackportRelease $pinnedRelease $Repository -Current
        $state.release = $pinnedRelease
        $state.main_team = Get-BackportMainTeam $source
    }
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $StatePath) -Force
    $state | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
    $issueLinks = if ($issues.Count -gt 0) { ($issues | ForEach-Object { $_.url }) -join ', ' } else { '(none)' }
    $teams = @($source.labels | ForEach-Object { $_.name } | Where-Object { $_ -clike 'Team:*' })
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
    $intentMatches = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:publication-intent:v1 sha=([0-9a-f]{40}) -->\r?$')
    if ($intentMatches.Count -gt 1 -or ($intentMatches.Count -eq 0 -and $Body.Contains('bc-extrequest-backport:publication-intent:'))) {
        throw 'Malformed or ambiguous tracking issue publication intent.'
    }
    if ($intentMatches.Count -eq 1) { return $intentMatches[0].Groups[1].Value }
    return $null
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
    if ($Object.ContainsKey('head')) {
        $expected = if ($State.ContainsKey('result')) { $State.result.commit } else { $null }
        if ($Object.head.sha -cnotmatch '^[0-9a-f]{40}$' -or ($expected -and $Object.head.sha -cne $expected)) {
            throw 'Existing backport PR does not contain the expected prepared commit.'
        }
    }
}

function Get-BackportIssueSummary {
    param([hashtable] $Issue)
    if (-not $Issue.ContainsKey('title') -or [string]::IsNullOrWhiteSpace($Issue.title)) {
        throw "Original issue $($Issue.url) has no title to summarize."
    }
    $summary = [regex]::Replace($Issue.title, '\s+', ' ').Trim()
    if ($summary -notmatch '[.!?]$') { $summary += '.' }
    return $summary
}

function Get-BackportDescription {
    param(
        [string] $Repository, [string] $Target, [object[]] $Issues, [long[]] $SourcePrs,
        [string] $Team = '', [long] $TrackingNumber = 0, [string] $Outcome = ''
    )

    $teamText = if ($Team) { " for $Team" } else { '' }
    $lines = @("Backporting of extensibility requests$teamText to ``$Target``.", '', 'Issues:')
    $originalIssues = @($Issues | Sort-Object url -Unique)
    if ($originalIssues.Count -eq 0) { $lines += 'No linked issues.' }
    foreach ($issue in $originalIssues) {
        $entry = "- $($issue.url)"
        if ($TrackingNumber -eq 0) { $entry += " - $(Get-BackportIssueSummary -Issue $issue)" }
        $lines += $entry
    }
    if ($TrackingNumber -gt 0) {
        $lines += @('', 'PRs:')
        foreach ($number in @($SourcePrs | Select-Object -Unique)) {
            $lines += "- https://github.com/$Repository/pull/$number"
        }
        $lines += @('', "Fixes #$TrackingNumber", '', '> [!IMPORTANT]',
            '> AI-generated: content may be inaccurate or incomplete. Please review and verify before relying on or merging.')
    }
    else {
        if ($Outcome -eq 'conflict') {
            $lines += @('', 'The complete source PR could not be cherry-picked cleanly. No partial branch or PR was published.',
                'A developer must resolve the backport manually; automatic runs do not retry this conflict.')
        }
        elseif ($Outcome -eq 'already-present') {
            $lines += @('', 'The changes are already present on the release branch. No empty backport PR was created.')
        }
        $lines += @('', '*Auto-generated content*')
    }
    return $lines -join "`n"
}

function Get-BackportTitle {
    param([hashtable] $State)
    if ($State.schema -eq 3) { return Get-BackportTitle $State.cohort }
    if ($State.schema -eq 2 -and $State.request.ContainsKey('mode') -and $State.request.mode -eq 'single') {
        return Get-BackportTitle $State.members[0]
    }
    if ($State.schema -eq 2) {
        $version = ($State.request.target -split '/')[1]
        $team = $State.request.team -replace '[\r\n]', ' '
        $date = Get-BackportDiscoveryDate $State.request
        $title = "[Backport $version] [Extensibility Requests] [$team] till $date"
    }
    else {
        $title = "[Backport $(($State.target -split '/')[1])] #$($State.source_pr): $($State.source_title -replace '[\r\n]', ' ')"
    }
    if ($title.Length -gt 240) { $title = $title.Substring(0, 240) }
    return $title
}

function Get-BackportBody {
    param([hashtable] $State, [AllowNull()][long] $TrackingNumber = 0)

    @(
        (Get-BackportMarker $State.source_pr $State.target $State.source_sha)
        "<!-- Preparation result: **$($State.result.outcome)**. -->"
        ''
        (Get-BackportDescription -Repository $State.repository -Target $State.target -Issues $State.issues `
            -SourcePrs @($State.source_pr) -TrackingNumber $TrackingNumber -Outcome $State.result.outcome)
    ) -join "`n"
}



function Publish-ExtRequestBackport {
    [CmdletBinding()]
    param([string] $StatePath, [string] $BotLogin, [hashtable] $PreparedState)

    $state = if ($null -ne $PreparedState) { $PreparedState }
        else { Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -AsHashtable -Depth 60 }
    if ($state.schema -eq 3) { Publish-BackportMilestone $state $StatePath $BotLogin; return }
    Publish-BackportLegacyOrPromote $state $StatePath $BotLogin
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

function Get-BackportRelease {
    param([string] $Repository, [string] $Target)
    Assert-BackportTarget $Target
    $content = Invoke-BackportApi "repos/$Repository/contents/.github/AL-Go-Settings.json?ref=$([uri]::EscapeDataString($Target))"
    if ($content.encoding -cne 'base64') { throw 'Target settings must be base64-encoded JSON content.' }
    $settings = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($content.content)) |
        ConvertFrom-Json -AsHashtable
    $value = $settings.repoVersion
    if ($null -eq $value -or $value -is [bool] -or $value -is [Collections.IDictionary] -or $value -is [array]) {
        throw 'Target settings have no valid repoVersion.'
    }
    $version = [Convert]::ToString($value, [Globalization.CultureInfo]::InvariantCulture)
    if ($version -cnotmatch '^([1-9][0-9]*)\.[0-9]+(?:\.[0-9]+)?$' -or
        [long]($version.Split('.')[0]) -ne [long](($Target.Split('/')[1]).Split('.')[0])) {
        throw 'Target repoVersion is invalid or its major version does not match the release branch.'
    }
    $title = "Version $version"
    $milestones = @(Get-BackportApiPages "repos/$Repository/milestones?state=all" | Where-Object { $_.title -ceq $title })
    if ($milestones.Count -ne 1) { throw "Expected exactly one milestone titled '$title'; found $($milestones.Count)." }
    if ($milestones[0].state -cne 'open') { throw "Milestone '$title' is closed; no publication is allowed." }
    if ([long]$milestones[0].number -le 0) { throw 'Resolved milestone has an invalid identity.' }
    return @{ target = $Target; version = $version; milestone_number = [long]$milestones[0].number; milestone_title = $title }
}

function Assert-BackportRelease {
    param([hashtable] $Release, [string] $Repository, [switch] $Current)
    Assert-BackportTarget $Release.target
    if ($Release.version -cnotmatch '^[1-9][0-9]*\.[0-9]+(?:\.[0-9]+)?$' -or
        $Release.milestone_title -cne "Version $($Release.version)" -or
        $Release.milestone_number -le 0 -or
        [long]$Release.version.Split('.')[0] -ne [long]$Release.target.Split('/')[1].Split('.')[0]) {
        throw 'Invalid pinned release/milestone identity.'
    }
    $milestone = Invoke-BackportApi "repos/$Repository/milestones/$($Release.milestone_number)"
    if ($milestone.title -cne $Release.milestone_title -or $milestone.state -cne 'open') {
        throw 'Pinned milestone is missing, changed or closed; it must never be reopened automatically.'
    }
    if ($Current -and (ConvertTo-BackportCanonicalJson (Get-BackportRelease $Repository $Release.target)) -cne
        (ConvertTo-BackportCanonicalJson $Release)) {
        throw 'Target version rollover detected; the prepared cohort remains pinned and must not silently move milestones.'
    }
}

function Get-BackportSharedTitle {
    param([hashtable] $Release)
    "[Backporting][$($Release.target)][Extensibility Requests][$($Release.milestone_title)]"
}

function Get-BackportSharedMarker {
    param([hashtable] $Release)
    "<!-- bc-extrequest-backport:tracker:v3 $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((ConvertTo-BackportCanonicalJson $Release)))) -->"
}

function Read-BackportSharedMarker {
    param([string] $Body)
    $found = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:tracker:v3 ([A-Za-z0-9+/=]+) -->\r?$')
    if ($found.Count -gt 1 -or ($found.Count -eq 0 -and $Body.Contains('bc-extrequest-backport:tracker:'))) {
        throw 'Malformed or ambiguous shared tracker identity.'
    }
    if ($found.Count -eq 1) {
        return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($found[0].Groups[1].Value)) | ConvertFrom-Json -AsHashtable
    }
    return $null
}

function Assert-BackportSharedTracker {
    param([hashtable] $Issue, [hashtable] $Release, [string] $BotLogin = '')
    $identity = Read-BackportSharedMarker $Issue.body
    if ($null -eq $identity -or (Get-BackportSharedMarker $identity) -cne (Get-BackportSharedMarker $Release) -or
        $Issue.title -cne (Get-BackportSharedTitle $Release) -or $Issue.user.login -cnotmatch '^[a-z0-9-]+\[bot\]$' -or
        ($BotLogin -and $Issue.user.login -cne $BotLogin) -or $null -eq $Issue.milestone -or
        $Issue.milestone.number -ne $Release.milestone_number -or $Issue.milestone.title -cne $Release.milestone_title -or
        ($Issue.ContainsKey('type') -and ($null -eq $Issue.type -or $Issue.type.name -cne 'Task')) -or
        $Issue.ContainsKey('pull_request')) { throw 'Shared tracker identity, milestone or App author is unexpected.' }
}

function Get-BackportSharedTracker {
    param([string] $Repository, [hashtable] $Release, [string] $BotLogin)
    $trackerCandidates = @(Get-BackportApiPages "repos/$Repository/issues?state=all&milestone=$($Release.milestone_number)" |
        Where-Object {
            if ($_.ContainsKey('pull_request')) { return $false }
            $identity = Read-BackportSharedMarker $_.body
            $_.title -ceq (Get-BackportSharedTitle $Release) -or
                ($null -ne $identity -and $identity.target -ceq $Release.target)
        })
    if ($trackerCandidates.Count -gt 1) { throw 'Duplicate shared milestone trackers; operator reconciliation is required.' }
    if ($trackerCandidates.Count -eq 1) {
        Assert-BackportSharedTracker $trackerCandidates[0] $Release $BotLogin
        return $trackerCandidates[0]
    }
    return $null
}

function Get-BackportMainTeam {
    param([hashtable] $Source)
    $teams = @($Source.labels | ForEach-Object { $_.name } | Where-Object { $_ -clike 'Team:*' } | Sort-Object -Unique)
    if ($teams.Count -eq 0) { return 'Unassigned' }
    if ($teams.Count -ne 1 -or $teams[0] -cnotmatch '^Team: *\S[^\r\n]*$') { return 'Ambiguous' }
    return $teams[0]
}

function Assert-BackportJournalState {
    param([hashtable] $State)
    if ($State.schema -ne 3) { throw 'Unsupported journal schema.' }
    Assert-BackportRepository $State.repository
    Assert-BackportBatchManifest $State.cohort
    if ($State.repository -cne $State.cohort.repository -or $State.release.target -cne $State.cohort.request.target -or
        $State.release.milestone_title -cne "Version $($State.release.version)" -or $State.release.milestone_number -le 0) {
        throw 'Journal release and cohort identities do not agree.'
    }
    if ($State.cohort.request.ContainsKey('release') -and
        (Get-BackportSharedMarker $State.release) -cne (Get-BackportSharedMarker $State.cohort.request.release)) {
        throw 'Pinned request release differs from the journal release.'
    }
    foreach ($member in $State.cohort.members) {
        if (-not $member.ContainsKey('main_team') -or
            ($member.main_team -notin @('Unassigned', 'Ambiguous') -and $member.main_team -cnotmatch '^Team: *\S[^\r\n]*$') -or
            ($State.cohort.request.mode -eq 'team' -and $member.main_team -cne $State.cohort.request.team)) {
            throw 'Journal original main-PR team metadata is missing or inconsistent.'
        }
    }
}

function Get-BackportJournalMarker {
    param([hashtable] $State)
    "<!-- bc-extrequest-backport:journal:v3 $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((ConvertTo-BackportCanonicalJson $State)))) -->"
}

function Read-BackportJournalMarker {
    param([string] $Body)
    $found = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:journal:v3 ([A-Za-z0-9+/=]+) -->\r?$')
    if ($found.Count -gt 1 -or ($found.Count -eq 0 -and $Body.Contains('bc-extrequest-backport:journal:'))) {
        throw 'Malformed or ambiguous cohort journal.'
    }
    if ($found.Count -eq 0) { return $null }
    $state = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($found[0].Groups[1].Value)) |
        ConvertFrom-Json -AsHashtable -Depth 80
    Assert-BackportJournalState $state
    return $state
}

function Assert-BackportJournal {
    param([hashtable] $Comment, [hashtable] $State, [string] $BotLogin)
    $found = Read-BackportJournalMarker $Comment.body
    if ($null -eq $found -or $Comment.user.login -cne $BotLogin -or
        (Get-BackportJournalMarker $found) -cne (Get-BackportJournalMarker $State)) {
        throw 'Cohort journal author or immutable manifest changed.'
    }
    $null = Read-BackportJournalPublication $Comment.body $State.cohort.head
    $null = Read-BackportBranchIntent $Comment.body $State.cohort.head
}

function Read-BackportBranchIntent {
    param([string] $Body, [string] $Head)
    $found = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:branch-intent:v1 sha=([0-9a-f]{40}) -->\r?$')
    if ($found.Count -gt 1 -or
        ($found.Count -eq 0 -and $Body.Contains('bc-extrequest-backport:branch-intent:')) -or
        ($found.Count -eq 1 -and $found[0].Groups[1].Value -cne $Head)) {
        throw 'Malformed, conflicting or changed branch publication intent.'
    }
    return $found.Count -eq 1
}

function Read-BackportJournalPublication {
    param([string] $Body, [string] $Head)
    $intent = Read-BackportPublicationIntent $Body
    if ($null -ne $intent -and $intent -cne $Head) { throw 'Journal publication intent SHA differs from the cohort.' }
    $markers = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:journal-pr:v1 number=([1-9][0-9]*) sha=([0-9a-f]{40}) -->\r?$')
    if ($markers.Count -gt 1 -or ($markers.Count -eq 0 -and $Body.Contains('bc-extrequest-backport:journal-pr:'))) {
        throw 'Malformed or conflicting journal PR identities.'
    }
    $complete = [regex]::Matches($Body, '(?m)^<!-- bc-extrequest-backport:journal-complete:v1 -->\r?$')
    if ($complete.Count -gt 1 -or ($complete.Count -eq 0 -and $Body.Contains('bc-extrequest-backport:journal-complete:'))) {
        throw 'Malformed or duplicate journal completion marker.'
    }
    if ($markers.Count -eq 1) {
        if ($markers[0].Groups[2].Value -cne $Head -or $null -eq $intent) { throw 'Journal PR proof or intent is invalid.' }
        return [long]$markers[0].Groups[1].Value
    }
    return $null
}

function Assert-BackportLegacyReplacement {
    param([hashtable] $State, [hashtable] $Legacy, [string] $BotLogin)
    if (-not $State.ContainsKey('legacy_issue') -or $State.legacy_issue -ne $Legacy.number) {
        throw 'Legacy replacement tracking identity differs.'
    }
    $batch = Read-BackportBatchMarker $Legacy.body
    if ($null -ne $batch) {
        Assert-BackportBatchObject $Legacy $batch $BotLogin
        $candidate = ConvertTo-BackportCanonicalJson $State.cohort | ConvertFrom-Json -AsHashtable -Depth 80
        for ($i = 0; $i -lt $candidate.members.Count; $i++) {
            if ($i -lt $batch.members.Count -and -not $batch.members[$i].ContainsKey('main_team')) {
                [void]$candidate.members[$i].Remove('main_team')
            }
        }
        if ((Get-BackportBatchMarker $candidate) -cne (Get-BackportBatchMarker $batch)) {
            throw 'Legacy replacement changed immutable membership, proofs or outcomes.'
        }
    }
    else {
        if ($State.cohort.request.mode -ne 'single' -or $State.cohort.members.Count -ne 1) {
            throw 'Standalone legacy tracking cannot replace an entire team cohort.'
        }
        Assert-BackportObject $Legacy $State.cohort.members[0] $BotLogin
    }
    if ($null -ne (Read-BackportPublicationIntent $Legacy.body)) { throw 'Legacy publication is unconfirmed.' }
}

function New-BackportLegacyJournal {
    param([hashtable] $Cohort, [hashtable] $Release, [object[]] $Metadata, [long] $IssueNumber)
    if ($IssueNumber -le 0) { throw 'Legacy cohort has no durable tracking issue identity.' }
    $copy = ConvertTo-BackportCanonicalJson $Cohort | ConvertFrom-Json -AsHashtable -Depth 80
    for ($i = 0; $i -lt $copy.members.Count; $i++) {
        if (-not $copy.members[$i].ContainsKey('main_team')) {
            $copy.members[$i].main_team = Get-BackportMainTeam $Metadata[$i].source
        }
    }
    $state = @{
        schema = 3; repository = $copy.repository; release = $Release; cohort = $copy; legacy_issue = $IssueNumber
    }
    Assert-BackportJournalState $state
    return $state
}

function Get-BackportJournalRecords {
    param([string] $Repository, [hashtable] $Tracker)
    $issues = if ($null -ne $Tracker) { @($Tracker) }
        else { @(Get-BackportApiPages "repos/$Repository/issues?state=all&labels=ext-backporting") }
    $records = @()
    foreach ($issue in $issues) {
        if ($issue.ContainsKey('pull_request')) { continue }
        $release = Read-BackportSharedMarker $issue.body
        if ($null -eq $release) { continue }
        Assert-BackportSharedTracker $issue $release
        foreach ($comment in @(Get-BackportApiPages "repos/$Repository/issues/$($issue.number)/comments")) {
            $state = Read-BackportJournalMarker $comment.body
            if ($null -eq $state) { continue }
            Assert-BackportJournal $comment $state $issue.user.login
            if ((Get-BackportSharedMarker $state.release) -cne (Get-BackportSharedMarker $release)) {
                throw 'Cohort journal is registered on the wrong milestone tracker.'
            }
            $records += @{ issue = $issue; journal = $comment; journal_state = $state; manifest = $state.cohort; shared = $true }
        }
    }
    $active = @{}
    foreach ($record in @($records | Sort-Object { [long]$_.journal.id })) {
        $state = $record.journal_state
        $numbers = @($state.cohort.request.source_prs)
        $prior = @($numbers | ForEach-Object { if ($active.ContainsKey([string]$_)) { $active[[string]$_] } } |
            Sort-Object { $_.journal.id } -Unique)
        if ($prior.Count -gt 0) {
            if ($prior.Count -ne 1 -or $numbers.Count -ne 1 -or $state.cohort.request.mode -ne 'single' -or
                -not $state.ContainsKey('supersedes') -or $state.supersedes -ne $prior[0].journal.id -or
                $prior[0].manifest.request.mode -ne 'single' -or
                $prior[0].manifest.members[0].result.outcome -ne 'conflict' -or
                (Get-BackportSharedMarker $state.release) -cne (Get-BackportSharedMarker $prior[0].journal_state.release) -or
                $state.cohort.members[0].source_sha -cne $prior[0].manifest.members[0].source_sha) {
                throw 'Duplicate/conflicting journal source membership or unsafe conflict retry.'
            }
            if ((Get-BackportCohortBranch $state.cohort) -cne (Get-BackportCohortBranch $prior[0].manifest)) {
                throw 'Conflict retry changed the pinned cohort branch.'
            }
        }
        elseif ($state.ContainsKey('supersedes')) { throw 'Conflict retry has no preceding cohort journal.' }
        foreach ($number in $numbers) { $active[[string]$number] = $record }
    }
    @($active.Values | Sort-Object { $_.journal.id } -Unique)
}

function Get-BackportTrackerLabels {
    param([object[]] $Members, [object[]] $Existing = @())
    $labels = @{}
    foreach ($label in @($Existing) + @($Members | ForEach-Object { $_.labels })) {
        if ($label.name -notmatch '^(Team:|Ownership:)' -and
            $label.name -notin @('ext-ready-to-implement', 'ext-backport-processed')) { $labels[$label.name] = $label }
    }
    $labels['ext-backporting'] = @{ name = 'ext-backporting'; color = '5319E7'; description = 'Tracks an extensibility backport.' }
    @($labels.Values | Sort-Object name)
}

function Get-BackportSharedBody {
    param([hashtable] $Release)
    @(
        (Get-BackportSharedMarker $Release)
        ''
        "Backporting of extensibility requests to ``$($Release.target)`` for **$($Release.milestone_title)**."
        ''
        '<!-- bc-extrequest-backport:table:start -->'
        '| Original issue | Original PR | Team | Backport PR |'
        '| --- | --- | --- | --- |'
        '<!-- bc-extrequest-backport:table:end -->'
        ''
        '*Auto-generated content*'
    ) -join "`n"
}

function ConvertTo-BackportTableText {
    param([string] $Text)
    $plain = [regex]::Replace($Text, '\s+', ' ').Trim()
    # Entities stay literal text to Markdown, including URL, mention and protocol punctuation.
    [regex]::Replace($plain, '[\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e]', {
        param($match)
        "&#$([int][char]$match.Value);"
    })
}

function Merge-BackportTrackerRows {
    param([string] $Body, [hashtable] $State, [hashtable] $Pull)
    $pattern = '(?s)(<!-- bc-extrequest-backport:table:start -->\r?\n\| Original issue \| Original PR \| Team \| Backport PR \|\r?\n\| --- \| --- \| --- \| --- \|)(.*?)(\r?\n<!-- bc-extrequest-backport:table:end -->)'
    $sections = [regex]::Matches($Body, $pattern)
    if ($sections.Count -ne 1) { throw 'Shared tracker managed table is missing or ambiguous; do not overwrite it.' }
    $rows = [ordered]@{}
    foreach ($line in $sections[0].Groups[2].Value.Trim().Split("`n", [StringSplitOptions]::RemoveEmptyEntries)) {
        $line = $line.TrimEnd("`r")
        if ($line -cmatch '^(?<cells>\| .* )\| (?<marker><!-- bc-extrequest-backport:row:[0-9a-f]{64} -->)$') {
            $line = "$($Matches.cells)$($Matches.marker) |"
        }
        if ($line -cnotmatch '^\| .* <!-- bc-extrequest-backport:row:([0-9a-f]{64}) --> \|$' -or
            [regex]::Matches($line, '\|').Count -ne 5) {
            throw 'Unrecognized managed tracker row; preserve it for operator reconciliation.'
        }
        $key = $Matches[1]
        if ($rows.Contains($key)) { throw 'Duplicate managed tracker rows.' }
        $rows[$key] = $line.TrimEnd("`r")
    }
    foreach ($member in $State.cohort.members) {
        $outcome = switch ($member.result.outcome) {
            'conflict' { 'Conflict - manual resolution needed' }
            'already-present' { 'Already present' }
            'applied' { if ($null -ne $Pull) { "[#$($Pull.number)]($($Pull.html_url))" } else { 'Pending publication' } }
        }
        $originals = @($member.issues | Sort-Object url -Unique)
        if ($originals.Count -eq 0) { $originals = ,$null }
        foreach ($issue in $originals) {
            $url = if ($null -eq $issue) { '' } else { $issue.url }
            $cell = if ($null -eq $issue) { 'No linked issue' }
                else { "[$($issue.url)]($($issue.url)) - $(ConvertTo-BackportTableText (Get-BackportIssueSummary $issue))" }
            $key = Get-BackportDigest "$($member.source_pr)|$url"
            $pr = "https://github.com/$($State.repository)/pull/$($member.source_pr)"
            $rows[$key] = "| $cell | [#$($member.source_pr)]($pr) | $(ConvertTo-BackportTableText $member.main_team) | $outcome <!-- bc-extrequest-backport:row:$key --> |"
        }
    }
    $replacement = $sections[0].Groups[1].Value + "`n" + ($rows.Values -join "`n") + $sections[0].Groups[3].Value
    $merged = $Body.Substring(0, $sections[0].Index) + $replacement + $Body.Substring($sections[0].Index + $sections[0].Length)
    if ($merged.Length -gt 65000) { throw 'Shared tracker table exceeds GitHub body limits; never truncate earlier cohorts.' }
    return $merged
}

function Assert-BackportTrackerCapacity {
    param([string] $Body, [hashtable] $State, [hashtable] $Pull)
    if ($null -eq $Pull) {
        # Reserve the complete eventual PR link, not the shorter pending text.
        $Pull = @{
            number = [long]::MaxValue
            html_url = "https://github.com/$($State.repository)/pull/$([long]::MaxValue)"
        }
    }
    $null = Merge-BackportTrackerRows $Body $State $Pull
}

function Assert-BackportBatchRequest {
    param([hashtable] $Request)
    foreach ($name in @('key', 'mode', 'source_prs', 'sources', 'target', 'team', 'batch_id', 'reference_time', 'manual')) {
        if (-not $Request.ContainsKey($name)) { throw "Missing batch request field $name." }
    }
    Assert-BackportTarget $Request.target
    if ($Request.ContainsKey('retry_conflict') -and $Request.retry_conflict -isnot [bool]) {
        throw 'Explicit conflict retry intent must be boolean.'
    }
    if ($Request.ContainsKey('tracking_issue') -or $Request.ContainsKey('state_digest') -or $Request.ContainsKey('journal_id')) {
        if (-not $Request.ContainsKey('tracking_issue') -or -not $Request.ContainsKey('state_digest') -or
            [string]$Request.tracking_issue -cnotmatch '^[1-9][0-9]*$' -or
            $Request.state_digest -cnotmatch '^[0-9a-f]{64}$' -or
            ($Request.ContainsKey('journal_id') -and [string]$Request.journal_id -cnotmatch '^[1-9][0-9]*$')) {
            throw 'Invalid immutable cohort registry reference.'
        }
    }
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
        if ($Request.team -cnotmatch '^Team: *\S[^\r\n]*$' -or $Request.manual) { throw 'Invalid team request.' }
        $identity = Get-BackportRequestCore $Request
        [void]$identity.Remove('key')
        $expected = 'team-' + (Get-BackportDigest (ConvertTo-BackportCanonicalJson $identity)).Substring(0, 32)
        if ($Request.key -cne $expected) { throw 'Batch membership or identity has changed.' }
    }
}

function Get-BackportRequestCore {
    param([hashtable] $Request)
    $core = @{} + $Request
    foreach ($name in @('manifest', 'journal_state', 'retry_conflict', 'tracking_issue', 'journal_id', 'state_digest')) {
        [void]$core.Remove($name)
    }
    return $core
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
    $null = Get-BackportCohortBranch $Manifest
    if ($Manifest.request.mode -notin @('team', 'single') -or
        (ConvertTo-BackportCanonicalJson $Manifest.request) -cne
            (ConvertTo-BackportCanonicalJson (Get-BackportRequestCore $Manifest.request)) -or
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
    $journals = @(Get-BackportJournalRecords $Repository)
    foreach ($issue in @(Get-BackportApiPages "repos/$Repository/issues?state=all&labels=ext-backporting")) {
        if ($issue.ContainsKey('pull_request')) { continue }
        $manifest = Read-BackportBatchMarker $issue.body
        if ($null -eq $manifest) { continue }
        $replacement = @($journals | Where-Object {
            $_.journal_state.ContainsKey('legacy_issue') -and $_.journal_state.legacy_issue -eq $issue.number
        })
        if ($replacement.Count -gt 1) { throw 'Multiple journals replace one legacy cohort.' }
        if ($replacement.Count -eq 1) {
            Assert-BackportLegacyReplacement $replacement[0].journal_state $issue $replacement[0].issue.user.login
            continue
        }
        foreach ($number in $manifest.request.source_prs) {
            if ($mapping.ContainsKey([string]$number)) { throw "Multiple batch mappings for source #$number." }
            $mapping[[string]$number] = $manifest.request.key
        }
        @{ issue = $issue; manifest = $manifest }
    }
    foreach ($record in $journals) {
        foreach ($number in $record.manifest.request.source_prs) {
            if ($mapping.ContainsKey([string]$number)) { throw "Multiple batch mappings for source #$number." }
            $mapping[[string]$number] = $record.manifest.request.key
        }
        $record
    }
}

function Get-BackportDiscoveryDate {
    param([hashtable] $Request)
    $zone = [TimeZoneInfo]::FindSystemTimeZoneById('Europe/Copenhagen')
    $localTime = [TimeZoneInfo]::ConvertTime([DateTimeOffset]$Request.reference_time, $zone)
    $localTime.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
}

function Get-BackportBranchBase {
    param([hashtable] $Request)
    if ($Request.mode -eq 'single') {
        return "bc-extrequest-backport/backport_$($Request.source_prs[0])"
    }
    $team = $Request.team -replace '^Team:\s*', ''
    $slug = [regex]::Replace($team.ToLowerInvariant(), '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { throw 'Team has no safe ASCII branch slug.' }
    "bc-extrequest-backport/$slug-$(Get-BackportDiscoveryDate $Request)"
}

function Get-BackportCohortBranch {
    param([hashtable] $Manifest)
    # Absence is meaningful: old manifests and their hashes must remain unchanged.
    if (-not $Manifest.ContainsKey('branch')) { return "bc-extrequest-backport/$($Manifest.request.key)" }
    $branch = $Manifest.branch
    if ($Manifest.request.mode -eq 'single' -and $branch -is [string] -and
        $branch -ceq (Get-BackportBranch $Manifest.request.source_prs[0] $Manifest.request.target)) { return $branch }
    $base = Get-BackportBranchBase $Manifest.request
    $pattern = '^' + [regex]::Escape($base) + '(?:-(?:[2-9]|[1-9][0-9]+))?$'
    if ($branch -isnot [string] -or $branch -cnotmatch $pattern) {
        throw 'Pinned cohort branch is malformed or differs from its source/team discovery identity.'
    }
    return $branch
}

function New-BackportCohortBranch {
    param([string] $Repository, [string] $Directory, [hashtable] $Request, [object[]] $Records)
    $base = Get-BackportBranchBase $Request
    $reserved = @($Records | ForEach-Object { Get-BackportCohortBranch $_.manifest })
    for ($suffix = 1; $suffix -le 10000; $suffix++) {
        $branch = if ($suffix -eq 1) { $base } else { "$base-$suffix" }
        if ($branch -cin $reserved) { continue }
        $remote = (Invoke-BackportGit $Directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
        if ($remote) { continue }
        if ($null -ne (Get-BackportBatchPull $Repository -Branch $branch)) { continue }
        return $branch
    }
    throw 'No free backport branch within the allocation limit; reconcile reservations manually.'
}

function Assert-BackportBranchReservation {
    param([hashtable] $State)
    $branch = Get-BackportCohortBranch $State.cohort
    foreach ($record in @(Get-BackportBatchRecords $State.repository)) {
        if ((Get-BackportCohortBranch $record.manifest) -cne $branch) { continue }
        if ($record.ContainsKey('shared') -and
            (Get-BackportJournalMarker $record.journal_state) -ceq (Get-BackportJournalMarker $State)) { continue }
        if ($State.ContainsKey('supersedes') -and $record.ContainsKey('shared') -and
            $State.supersedes -eq $record.journal.id -and
            $State.cohort.request.mode -eq 'single' -and $record.manifest.request.mode -eq 'single' -and
            $State.cohort.members[0].source_pr -eq $record.manifest.members[0].source_pr -and
            $State.cohort.members[0].source_sha -ceq $record.manifest.members[0].source_sha -and
            $record.manifest.members[0].result.outcome -eq 'conflict') { continue }
        if ($State.ContainsKey('legacy_issue') -and -not $record.ContainsKey('shared') -and
            $State.legacy_issue -eq $record.issue.number) { continue }
        throw 'Pinned backport branch is reserved by another immutable cohort; rediscover before publication.'
    }
}

function Get-BackportBatchPull {
    param([string] $Repository, [string] $Key, [string] $Branch = '')
    if (-not $Branch) { $Branch = "bc-extrequest-backport/$Key" }
    $owner = $Repository.Split('/')[0]
    $pulls = @(Get-BackportApiPages "repos/$Repository/pulls?state=all&head=$owner`:$Branch")
    if ($pulls.Count -gt 1) { throw 'Multiple PRs for one batch branch.' }
    if ($pulls.Count -eq 1) { return $pulls[0] }
    return $null
}

function Assert-BackportSourceAliases {
    param([string] $Repository, [long] $SourcePr, [string] $Target)
    $aliases = @()
    $native = Get-BackportPull $Repository $SourcePr $Target
    if ($null -ne $native) { $aliases += $native }
    $single = Get-BackportBatchPull $Repository -Branch "bc-extrequest-backport/single-$SourcePr"
    if ($null -ne $single) { $aliases += $single }
    if ($aliases.Count -gt 1) {
        throw 'Ambiguous legacy standalone backport PR aliases; operator reconciliation is required.'
    }
    if ($aliases.Count -eq 1) {
        throw 'An existing standalone backport PR on a legacy alias is foreign or unregistered; reconcile its source identity, never duplicate or adopt it.'
    }
}

function Get-BackportSourceTeam {
    param([hashtable] $Source, [object[]] $Issues, [string] $Repository)
    $teams = @($Source.labels | ForEach-Object { $_.name } | Where-Object { $_ -clike 'Team:*' })
    if ($teams.Count -ne 1 -or $teams[0] -cnotmatch '^Team: *\S[^\r\n]*$') { return '' }
    foreach ($issue in $Issues) {
        $issueTeams = @($issue.labels.nodes | ForEach-Object { $_.name } | Where-Object { $_ -clike 'Team:*' })
        if ($issueTeams.Count -ne 1 -or $issueTeams[0] -cne $teams[0] -or
            -not $issue.ContainsKey('repository') -or $null -eq $issue.repository -or
            -not $issue.repository.ContainsKey('nameWithOwner') -or $issue.repository.nameWithOwner -cne $Repository) { return '' }
    }
    return $teams[0]
}

function Get-BackportResumeRequest {
    param([hashtable] $Record, [switch] $Manual)
    $row = @{} + $Record.manifest.request
    $row.tracking_issue = $Record.issue.number
    $state = $Record.manifest
    if ($Record.ContainsKey('shared')) {
        $row.journal_id = $Record.journal.id
        $state = $Record.journal_state
        if ($Manual -and $row.mode -eq 'single' -and $state.cohort.members[0].result.outcome -eq 'conflict') {
            $row.retry_conflict = $true
        }
    }
    $row.state_digest = Get-BackportDigest (ConvertTo-BackportCanonicalJson $state)
    Assert-BackportBatchRequest $row
    return $row
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
            return Get-BackportResumeRequest $mapped[$SourcePr] -Manual
        }
    }
    $candidates = @(Find-ExtRequestBackport $Repository -SourcePr $SourcePr -TargetOverride $TargetOverride -ReferenceTime ([DateTimeOffset]$clock))
    # A durable cohort survives the discovery window. Completed sources need no
    # lifecycle polling; resume only missing processed flags or independent records.
    if (-not $SourcePr) {
        foreach ($record in $records) {
            $unfinished = $false
            if ($record.ContainsKey('shared')) {
                $unfinished = -not $record.journal.body.Contains('<!-- bc-extrequest-backport:journal-complete:v1 -->')
                if ($unfinished) {
                    $row = Get-BackportResumeRequest $record
                    $requests[$row.key] = $row
                }
                continue
            }
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
                $row = Get-BackportResumeRequest $record
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
        $row.release = Get-BackportRelease $Repository $row.target
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
        $identity = Get-BackportRequestCore $request
        if ($stored.request.key -cne $request.key -or
            (ConvertTo-BackportCanonicalJson $stored.request) -cne (ConvertTo-BackportCanonicalJson $identity)) {
            throw 'Request differs from the existing immutable batch; rediscover it.'
        }
        if ($request.ContainsKey('tracking_issue')) {
            $current = Get-BackportResumeRequest $overlap[0]
            if ($current.tracking_issue -ne $request.tracking_issue -or $current.state_digest -cne $request.state_digest -or
                $current.ContainsKey('journal_id') -ne $request.ContainsKey('journal_id') -or
                ($request.ContainsKey('journal_id') -and $current.journal_id -ne $request.journal_id)) {
                throw 'Immutable cohort registry reference changed; rediscover it.'
            }
        }
        $request = $stored.request
    }
    elseif ($request.ContainsKey('manifest') -or $request.ContainsKey('journal_state') -or $request.ContainsKey('tracking_issue')) {
        throw 'Previously discovered batch tracking issue or journal is missing.'
    }
    $metadata = @(Assert-BackportBatchSources $request $Repository -Resume:$resume)
    $shared = $resume -and $overlap[0].ContainsKey('shared')
    $retryConflict = $false
    # The stored request is immutable; retry intent belongs to the invocation, not its identity.
    if ($shared) {
        $inputRow = ConvertFrom-Json $RequestJson -AsHashtable -Depth 80
        $retryConflict = $inputRow.ContainsKey('retry_conflict') -and $inputRow.retry_conflict -and
            $stored.request.mode -eq 'single' -and $stored.members[0].result.outcome -eq 'conflict'
    }
    $root = Split-Path -Parent $StatePath
    $null = New-Item -ItemType Directory -Path $root -Force
    if ($request.mode -eq 'single' -and -not $shared -and $null -ne (Get-BackportTracking $Repository $request.source_prs[0])) {
        if ($request.ContainsKey('release')) { Assert-BackportRelease $request.release $Repository -Current }
        New-ExtRequestBackport $Repository $request.source_prs[0] $request.target $request.manual $StatePath `
            -ReferenceTime ([DateTimeOffset]$request.reference_time)
        if ($request.ContainsKey('release')) { Assert-BackportRelease $request.release $Repository -Current }
        $single = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -AsHashtable -Depth 60
        if ($single.schema -eq 1 -and $single.source_sha -cne $request.sources[0].sha) {
            throw 'Independent source proof changed during preparation.'
        }
        if ($request.ContainsKey('release') -and $single.ContainsKey('release') -and
            (Get-BackportSharedMarker $request.release) -cne (Get-BackportSharedMarker $single.release)) {
            throw 'Independent preparation changed the discovered release; rediscover it.'
        }
        return
    }
    $recordBody = if ($shared) { $overlap[0].journal.body } elseif ($resume) { $overlap[0].issue.body } else { '' }
    $existingPull = if ($resume) { Get-BackportBatchPull $Repository -Branch (Get-BackportCohortBranch $stored) } else { $null }
    $intent = Read-BackportPublicationIntent $recordBody
    $release = if ($shared) { $overlap[0].journal_state.release }
        elseif ($request.ContainsKey('release')) { $request.release }
        elseif (-not $resume -or ($null -eq $existingPull -and $null -eq $intent)) { Get-BackportRelease $Repository $request.target }
        else { $null }
    if ($null -ne $release) { Assert-BackportRelease $release $Repository -Current:(-not $resume) }
    if ($resume -and ($null -ne $existingPull -or $null -ne $intent -or
        (-not $retryConflict -and @($stored.members | Where-Object { $_.result.outcome -eq 'applied' }).Count -eq 0))) {
        $output = if ($shared) { $overlap[0].journal_state } else { $stored }
        if (-not $shared -and $null -eq $existingPull -and $null -eq $intent) {
            Assert-BackportRelease $release $Repository -Current
            $output = New-BackportLegacyJournal $stored $release $metadata $overlap[0].issue.number
        }
        $output | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
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
    $branch = if ($resume) { Get-BackportCohortBranch $stored }
        else { New-BackportCohortBranch $Repository $directory $request $records }
    $targetSha = if ($resume -and -not $retryConflict) { $stored.target_sha }
        else { (Invoke-BackportApi "repos/$Repository/git/ref/heads/$($request.target)").object.sha }
    $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
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
            main_team = Get-BackportMainTeam $metadata[$i].source
            labels = @(Get-BackportLabels $metadata[$i].issues $metadata[$i].source.labels); result = $result
        }
        if ($result.outcome -eq 'applied') { $tip = $result.commit }
    }
    $manifest = @{
        schema = 2; repository = $Repository; request = $request; members = $members; target_sha = $targetSha
        head = $tip; tree = (Invoke-BackportGit $directory @('rev-parse', "$tip`^{tree}")).text.Trim()
    }
    if (-not $resume) { $manifest.branch = $branch }
    elseif ($stored.ContainsKey('branch')) { $manifest.branch = $stored.branch }
    if ($resume -and -not $retryConflict) {
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
    $output = $manifest
    if (-not $resume -or $shared) {
        $output = @{ schema = 3; repository = $Repository; release = $release; cohort = $manifest }
        if ($retryConflict) { $output.supersedes = $overlap[0].journal.id }
        elseif ($shared) { $output = $overlap[0].journal_state }
        Assert-BackportJournalState $output
    }
    else { $output = New-BackportLegacyJournal $manifest $release $metadata $overlap[0].issue.number }
    if (-not $shared) { Assert-BackportRelease $release $Repository -Current }
    $output | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
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
    $included = @($Manifest.members | Where-Object { $_.result.outcome -eq 'applied' })
    $body = @(
        (Get-BackportBatchMarker $Manifest)
        ''
        (Get-BackportDescription -Repository $Manifest.repository -Target $Manifest.request.target `
            -Issues @($included | ForEach-Object { $_.issues }) -SourcePrs @($included | ForEach-Object { $_.source_pr }) `
            -Team $Manifest.request.team -TrackingNumber $TrackingNumber)
    ) -join "`n"
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
            $team = if ($member.ContainsKey('main_team')) { $member.main_team }
                elseif ($Manifest.request.team) { $Manifest.request.team } else { 'Unassigned' }
            Write-BackportSummary "- Main PR https://github.com/$($Manifest.repository)/pull/$($member.source_pr); $team; target ``$($Manifest.request.target)``; source ``$($member.source_sha)``; outcome **$($member.result.outcome)**; original issues: $issues"
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
        ($Object.head.ref -cne (Get-BackportCohortBranch $Manifest) -or
        $Object.head.sha -cne $Manifest.head -or $Object.head.repo.full_name -cne $Manifest.repository -or
        $Object.base.ref -cne $Manifest.request.target -or $Object.base.repo.full_name -cne $Manifest.repository)) {
        throw 'Batch PR branch, target or provenance changed; never adopt human changes.'
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
    if ($manifest.schema -eq 3) { Publish-BackportMilestone $manifest $StatePath $BotLogin; return }
    Publish-BackportLegacyOrPromote $manifest $StatePath $BotLogin
}

function Get-BackportMilestonePullBody {
    param([hashtable] $State, [long] $TrackerNumber)
    $members = @($State.cohort.members | Where-Object { $_.result.outcome -eq 'applied' })
    $team = if ($State.cohort.request.mode -eq 'team') { $State.cohort.request.team } else { '' }
    $body = @((Get-BackportJournalMarker $State), '',
        (Get-BackportDescription $State.repository $State.release.target @($members | ForEach-Object { $_.issues }) `
            @($members | ForEach-Object { $_.source_pr }) -Team $team -TrackingNumber $TrackerNumber)) -join "`n"
    if ($body.Length -gt 65000) { throw 'Cohort proof exceeds GitHub body limits; never truncate membership.' }
    return $body
}

function Assert-BackportMilestonePull {
    param([hashtable] $Pull, [hashtable] $State, [string] $BotLogin)
    $found = Read-BackportJournalMarker $Pull.body
    if ($null -eq $found -or (Get-BackportJournalMarker $found) -cne (Get-BackportJournalMarker $State) -or
        $Pull.user.login -cne $BotLogin -or $Pull.head.sha -cne $State.cohort.head -or
        $Pull.head.ref -cne (Get-BackportCohortBranch $State.cohort) -or
        $Pull.head.repo.full_name -cne $State.repository -or $Pull.base.repo.full_name -cne $State.repository -or
        $Pull.base.ref -cne $State.release.target) { throw 'Backport PR author, branch, milestone cohort or SHA proof changed.' }
    if ($null -ne $Pull.milestone -and $Pull.milestone.number -ne $State.release.milestone_number) {
        throw 'Backport PR has a different milestone; do not overwrite human changes.'
    }
}

function Update-BackportJournal {
    param([hashtable] $State, [hashtable] $Comment, [string] $Addition, [string] $BotLogin)
    $path = "repos/$($State.repository)/issues/comments/$($Comment.id)"
    $fresh = Invoke-BackportApi $path
    Assert-BackportJournal $fresh $State $BotLogin
    if (-not $fresh.body.Contains($Addition)) {
        $body = "$($fresh.body)`n$Addition"
        if ($body.Length -gt 65000) { throw 'Cohort journal exceeds GitHub body limits.' }
        $candidate = @{} + $fresh
        $candidate.body = $body
        Assert-BackportJournal $candidate $State $BotLogin
        $null = Invoke-BackportApi $path -Method PATCH -Body @{ body = $body }
    }
    $confirmed = Invoke-BackportApi $path
    Assert-BackportJournal $confirmed $State $BotLogin
    if (-not $confirmed.body.Contains($Addition)) { throw 'Journal update was not independently confirmed.' }
    return $confirmed
}

function Assert-BackportNewCohort {
    param([hashtable] $State, [string] $BotLogin, [bool] $LegacyBatch)
    $repository = $State.repository
    $cohort = $State.cohort
    $observed = @(Get-BackportJournalRecords $repository)
    $exact = @($observed | Where-Object {
        (Get-BackportJournalMarker $_.journal_state) -ceq (Get-BackportJournalMarker $State)
    })
    if ($exact.Count -eq 1) {
        Assert-BackportSharedTracker $exact[0].issue $State.release $BotLogin
        Assert-BackportJournal $exact[0].journal $State $BotLogin
        return $exact[0]
    }
    foreach ($other in @($observed | Where-Object {
        @($_.manifest.request.source_prs | Where-Object { $_ -in $cohort.request.source_prs }).Count -gt 0
    })) {
        if (-not $State.ContainsKey('supersedes') -or $State.supersedes -ne $other.journal.id -or
            $cohort.request.mode -ne 'single' -or $other.manifest.request.mode -ne 'single' -or
            $other.manifest.members[0].result.outcome -ne 'conflict' -or
            $other.manifest.members[0].source_sha -cne $cohort.members[0].source_sha -or
            (Get-BackportSharedMarker $other.journal_state.release) -cne (Get-BackportSharedMarker $State.release)) {
            throw 'Cohort membership changed before publication.'
        }
    }
    foreach ($member in $cohort.members) {
        Assert-BackportSourceAliases $repository $member.source_pr $member.target
        $source = Get-BackportSource $repository $member.source_pr
        if ($source.merge_commit_sha -cne $member.source_sha) { throw 'Source SHA changed before publication.' }
        if ('ext-backport-processed' -in @($source.labels | ForEach-Object { $_.name })) {
            throw 'Processed source has no matching journal; fail closed.'
        }
        $tracking = if (-not $LegacyBatch) { Get-BackportTracking $repository $member.source_pr } else { $null }
        if ($null -ne $tracking -and (-not $State.ContainsKey('legacy_issue') -or $tracking.number -ne $State.legacy_issue)) {
            throw 'Source acquired a legacy tracking identity; do not duplicate it.'
        }
    }
    $oldBatches = @(Get-BackportBatchRecords $repository | Where-Object {
        -not $_.ContainsKey('shared') -and
        @($_.manifest.request.source_prs | Where-Object { $_ -in $cohort.request.source_prs }).Count -gt 0
    })
    if (@($oldBatches | Where-Object {
        -not $State.ContainsKey('legacy_issue') -or $_.issue.number -ne $State.legacy_issue
    }).Count -gt 0) { throw 'Source acquired a legacy batch identity; do not duplicate it.' }
    Assert-BackportBranchReservation $State
    if ($null -ne (Get-BackportBatchPull $repository -Branch (Get-BackportCohortBranch $cohort))) {
        throw 'Unregistered PR appeared before journal creation.'
    }
}

function Publish-BackportMilestone {
    param([hashtable] $State, [string] $StatePath, [string] $BotLogin)
    if ($BotLogin -cnotmatch '^[a-z0-9-]+\[bot\]$') { throw 'Invalid App identity.' }
    Assert-BackportJournalState $State
    $repository = $State.repository
    $cohort = $State.cohort
    $release = $State.release
    Assert-BackportBranchReservation $State
    $records = @(Get-BackportJournalRecords $repository)
    $overlap = @($records | Where-Object {
        @($_.manifest.request.source_prs | Where-Object { $_ -in $cohort.request.source_prs }).Count -gt 0
    })
    if ($overlap.Count -gt 1) { throw 'Prepared cohort overlaps multiple immutable journal records.' }
    $record = if ($overlap.Count -eq 1) { $overlap[0] } else { $null }
    $same = $null -ne $record -and (Get-BackportJournalMarker $record.journal_state) -ceq (Get-BackportJournalMarker $State)
    $revision = $null -ne $record -and $State.ContainsKey('supersedes') -and $State.supersedes -eq $record.journal.id -and
        $cohort.request.mode -eq 'single' -and $record.manifest.request.mode -eq 'single' -and
        $record.manifest.members[0].result.outcome -eq 'conflict' -and
        $cohort.members[0].source_sha -ceq $record.manifest.members[0].source_sha -and
        (Get-BackportSharedMarker $release) -ceq (Get-BackportSharedMarker $record.journal_state.release)
    if ($null -ne $record -and -not $same -and -not $revision) { throw 'Source membership already belongs to another immutable cohort.' }
    if ($revision -and (Get-BackportCohortBranch $cohort) -cne (Get-BackportCohortBranch $record.manifest)) {
        throw 'Conflict retry changed the pinned cohort branch.'
    }
    $legacyBatch = $false
    if ($State.ContainsKey('legacy_issue')) {
        $legacy = Invoke-BackportApi "repos/$repository/issues/$($State.legacy_issue)"
        Assert-BackportLegacyReplacement $State $legacy $BotLogin
        $legacyBatch = $null -ne (Read-BackportBatchMarker $legacy.body)
    }
    $null = @(Assert-BackportBatchSources $cohort.request $repository -Resume:($null -ne $record -or $State.ContainsKey('legacy_issue')))
    Assert-BackportRelease $release $repository
    $pull = Get-BackportBatchPull $repository -Branch (Get-BackportCohortBranch $cohort)
    $comment = if ($same) { $record.journal } else { $null }
    if ($null -ne $comment) {
        Assert-BackportJournal $comment $State $BotLogin
        $number = Read-BackportJournalPublication $comment.body $cohort.head
        if ($null -ne $number) {
            if ($null -ne $pull -and $pull.number -ne $number) { throw 'Branch lookup conflicts with the confirmed journal PR.' }
            $pull = Invoke-BackportApi "repos/$repository/pulls/$number"
            if ($null -eq $pull -or $pull.number -ne $number) { throw 'Confirmed journal PR is missing; do not repeat POST.' }
        }
    }
    if ($null -ne $pull) {
        if (-not $same) { throw 'Backport PR has no matching immutable journal.' }
        Assert-BackportMilestonePull $pull $State $BotLogin
        if ($null -eq (Read-BackportPublicationIntent $comment.body)) {
            throw 'Existing PR has no confirmed journal publication intent; reconcile manually.'
        }
    }
    if ($null -eq $pull) {
        if ($null -ne $comment -and $null -ne (Read-BackportPublicationIntent $comment.body)) {
            throw 'Previous PR creation is unconfirmed in the cohort journal; do not repeat POST.'
        }
        $applied = @($cohort.members | Where-Object { $_.result.outcome -eq 'applied' })
        if (-not $same -or $applied.Count -gt 0) { Assert-BackportRelease $release $repository -Current }
        if ($applied.Count -gt 0 -or (-not $same -and -not $legacyBatch)) {
            Assert-BackportPreparedBatch $cohort (Join-Path (Split-Path -Parent $StatePath) 'git')
        }
        if ($cohort.ContainsKey('branch') -and -not $same -and -not $State.ContainsKey('legacy_issue')) {
            $directory = Join-Path (Split-Path -Parent $StatePath) 'git'
            $branch = Get-BackportCohortBranch $cohort
            $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
            if ($remote) { throw 'Pinned branch appeared before its durable reservation; never overwrite or adopt it.' }
        }
    }
    $null = Get-BackportMilestonePullBody $State 9999999999
    if (-not $same) { $null = Assert-BackportNewCohort $State $BotLogin $legacyBatch }
    $tracker = Get-BackportSharedTracker $repository $release $BotLogin
    if ($null -eq $tracker) {
        $tracker = Get-BackportSharedTracker $repository $release $BotLogin
    }
    $capacityBody = if ($null -eq $tracker) { Get-BackportSharedBody $release } else { $tracker.body }
    Assert-BackportTrackerCapacity $capacityBody $State $pull
    if (-not $same) { Assert-BackportRelease $release $repository -Current }
    if ($null -eq $tracker) {
        $labels = @(Get-BackportTrackerLabels $cohort.members)
        Ensure-BackportLabels $repository $labels
        $tracker = New-BackportTrackingTask $repository @{
            title = Get-BackportSharedTitle $release; body = Get-BackportSharedBody $release
            type = 'Task'; milestone = $release.milestone_number; labels = @($labels | ForEach-Object { $_.name })
        }
        Assert-BackportSharedTracker $tracker $release $BotLogin
    }
    Assert-BackportSharedTracker $tracker $release $BotLogin
    if ($tracker.state -eq 'closed') {
        Assert-BackportRelease $release $repository -Current:(-not $same)
        $null = Invoke-BackportApi "repos/$repository/issues/$($tracker.number)" -Method PATCH -Body @{ state = 'open' }
        $tracker = Invoke-BackportApi "repos/$repository/issues/$($tracker.number)"
        Assert-BackportSharedTracker $tracker $release $BotLogin
        if ($tracker.state -cne 'open') { throw 'Shared tracker reopen was not confirmed.' }
    }
    if ($null -eq $comment) {
        $observed = @(Get-BackportJournalRecords $repository -Tracker $tracker)
        $matchingJournals = @($observed | Where-Object { (Get-BackportJournalMarker $_.journal_state) -ceq (Get-BackportJournalMarker $State) })
        if ($matchingJournals.Count -gt 1) { throw 'Duplicate cohort journals.' }
        if ($matchingJournals.Count -eq 1) { $comment = $matchingJournals[0].journal }
        else {
            $other = @($observed | Where-Object {
                @($_.manifest.request.source_prs | Where-Object { $_ -in $cohort.request.source_prs }).Count -gt 0
            })
            if ($other.Count -gt 0 -and (-not $revision -or $other.Count -ne 1 -or $other[0].journal.id -ne $State.supersedes)) {
                throw 'Cohort membership changed before journal creation.'
            }
            $appeared = Assert-BackportNewCohort $State $BotLogin $legacyBatch
            if ($null -ne $appeared) {
                if ($appeared.issue.number -ne $tracker.number) { throw 'Journal appeared on another shared tracker; reconcile duplicate trackers.' }
                $comment = $appeared.journal
            }
            else {
                Assert-BackportRelease $release $repository -Current
                $body = (Get-BackportJournalMarker $State) + "`n`nImmutable extensibility backport cohort."
                if ($body.Length -gt 64000) { throw 'Cohort journal exceeds GitHub body limits.' }
                try {
                    $created = Invoke-BackportApi "repos/$repository/issues/$($tracker.number)/comments" -Method POST -Body @{ body = $body }
                    $comment = Invoke-BackportApi "repos/$repository/issues/comments/$($created.id)"
                }
                catch { throw "Cohort journal creation is unconfirmed; no POST retry was attempted. Operator investigation is required. $($_.Exception.Message)" }
            }
            Assert-BackportJournal $comment $State $BotLogin
        }
    }
    Assert-BackportJournal $comment $State $BotLogin
    Assert-BackportBranchReservation $State
    if ($null -eq $pull -and @($cohort.members | Where-Object { $_.result.outcome -eq 'applied' }).Count -gt 0) {
        $guardedBranch = $cohort.ContainsKey('branch') -and -not $State.ContainsKey('legacy_issue')
        if ($guardedBranch) {
            foreach ($member in $cohort.members) {
                Assert-BackportSourceAliases $repository $member.source_pr $member.target
            }
        }
        Assert-BackportRelease $release $repository -Current
        $directory = Join-Path (Split-Path -Parent $StatePath) 'git'
        Assert-BackportBranchReservation $State
        $branch = Get-BackportCohortBranch $cohort
        $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
        $branchIntent = Read-BackportBranchIntent $comment.body $cohort.head
        if ($remote) {
            if (($remote -split '\s+')[0] -cne $cohort.head) { throw 'Existing branch differs; never overwrite human changes.' }
            if ($guardedBranch -and -not $branchIntent) {
                throw 'Existing branch has no confirmed branch publication intent; never adopt it.'
            }
        }
        else {
            if ($guardedBranch -and -not $branchIntent) {
                $comment = Update-BackportJournal $State $comment "<!-- bc-extrequest-backport:branch-intent:v1 sha=$($cohort.head) -->" $BotLogin
                Assert-BackportBranchReservation $State
                $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
                if ($remote) { throw 'Pinned branch appeared before push; never overwrite or adopt it.' }
            }
            Publish-BackportBranchCreateOnly $directory $branch $cohort.head
            $remote = (Invoke-BackportGit $directory @('ls-remote', '--heads', 'origin', "refs/heads/$branch")).text.Trim()
            if (($remote -split '\s+')[0] -cne $cohort.head) { throw 'Branch publication was not confirmed.' }
        }
        Assert-BackportBranchReservation $State
        $pull = Get-BackportBatchPull $repository -Branch $branch
        if ($null -eq $pull) {
            if ($null -ne (Read-BackportPublicationIntent $comment.body)) { throw 'Previous PR POST is unconfirmed; do not repeat it.' }
            Assert-BackportRelease $release $repository -Current
            $tracker = Invoke-BackportApi "repos/$repository/issues/$($tracker.number)"
            Assert-BackportSharedTracker $tracker $release $BotLogin
            Assert-BackportTrackerCapacity $tracker.body $State
            Assert-BackportBranchReservation $State
            if ($guardedBranch) {
                foreach ($member in $cohort.members) {
                    Assert-BackportSourceAliases $repository $member.source_pr $member.target
                }
            }
            $intent = "<!-- bc-extrequest-backport:publication-intent:v1 sha=$($cohort.head) -->"
            $comment = Update-BackportJournal $State $comment $intent $BotLogin
            try {
                $created = Invoke-BackportApi "repos/$repository/pulls" -Method POST -Body @{
                    title = Get-BackportTitle $State; body = Get-BackportMilestonePullBody $State $tracker.number
                    head = $branch; base = $release.target; draft = $true
                }
                $pull = Invoke-BackportApi "repos/$repository/pulls/$($created.number)"
            }
            catch { throw "PR creation is unconfirmed; no POST retry was attempted. Reconcile the journal before retrying. $($_.Exception.Message)" }
        }
        Assert-BackportMilestonePull $pull $State $BotLogin
    }
    if ($null -ne $pull) {
        Assert-BackportMilestonePull $pull $State $BotLogin
        if ($null -eq $pull.milestone) {
            $null = Invoke-BackportApi "repos/$repository/issues/$($pull.number)" -Method PATCH -Body @{ milestone = $release.milestone_number }
            $pull = Invoke-BackportApi "repos/$repository/pulls/$($pull.number)"
            Assert-BackportMilestonePull $pull $State $BotLogin
            if ($null -eq $pull.milestone) { throw 'PR milestone assignment was not confirmed.' }
        }
        $comment = Update-BackportJournal $State $comment "<!-- bc-extrequest-backport:journal-pr:v1 number=$($pull.number) sha=$($cohort.head) -->" $BotLogin
        $labels = @(Get-BackportBatchLabels $cohort)
        Ensure-BackportLabels $repository $labels
        $null = Invoke-BackportApi "repos/$repository/issues/$($pull.number)/labels" -Method POST -Body @{
            labels = @($labels | ForEach-Object { $_.name })
        }
    }
    $tracker = Invoke-BackportApi "repos/$repository/issues/$($tracker.number)"
    Assert-BackportSharedTracker $tracker $release $BotLogin
    Assert-BackportRelease $release $repository
    $body = Merge-BackportTrackerRows $tracker.body $State $pull
    $labels = @(Get-BackportTrackerLabels $cohort.members $tracker.labels)
    Ensure-BackportLabels $repository $labels
    $null = Invoke-BackportApi "repos/$repository/issues/$($tracker.number)" -Method PATCH -Body @{
        body = $body; labels = @($labels | ForEach-Object { $_.name }); milestone = $release.milestone_number
    }
    $confirmed = Invoke-BackportApi "repos/$repository/issues/$($tracker.number)"
    Assert-BackportSharedTracker $confirmed $release $BotLogin
    if ($confirmed.body -cne $body) { throw 'Shared tracker table update was not confirmed.' }
    if ($null -ne $pull) {
        foreach ($member in $cohort.members) {
            if ($member.result.outcome -eq 'applied') { Set-BackportProcessed $repository $member.source_pr }
        }
    }
    $null = Update-BackportJournal $State $comment '<!-- bc-extrequest-backport:journal-complete:v1 -->' $BotLogin
    Write-BackportBatchSummary $cohort 'published' "$($tracker.html_url) $(if ($null -ne $pull) { $pull.html_url })"
}

function Publish-BackportLegacyOrPromote {
    param([hashtable] $State, [string] $StatePath, [string] $BotLogin)
    if ($BotLogin -cnotmatch '^[a-z0-9-]+\[bot\]$') { throw 'Invalid App identity.' }
    $repository = $State.repository
    Assert-BackportRepository $repository
    if ($State.schema -eq 1 -and $State.ContainsKey('batch_key')) {
        $batches = @(Get-BackportBatchRecords $repository | Where-Object { $_.manifest.request.key -ceq $State.batch_key })
        if ($batches.Count -ne 1) { throw 'Legacy exception has no unique immutable cohort.' }
        $member = @($batches[0].manifest.members | Where-Object source_pr -eq $State.source_pr)
        if ($member.Count -ne 1 -or $member[0].result.outcome -eq 'applied' -or
            $member[0].source_sha -cne $State.source_sha -or
            (ConvertTo-BackportCanonicalJson $member[0].result) -cne (ConvertTo-BackportCanonicalJson $State.result)) {
            throw 'Legacy exception differs from its frozen cohort.'
        }
        if ($batches[0].ContainsKey('shared')) {
            Publish-BackportMilestone $batches[0].journal_state $StatePath $BotLogin
        } else { Publish-BackportLegacyOrPromote $batches[0].manifest $StatePath $BotLogin }
        return
    }
    $numbers = if ($State.schema -eq 1) { @($State.source_pr) } elseif ($State.schema -eq 2) { @($State.request.source_prs) }
        else { throw 'Unsupported publication state.' }
    $existing = @(Get-BackportJournalRecords $repository | Where-Object {
        @($_.manifest.request.source_prs | Where-Object { $_ -in $numbers }).Count -gt 0
    })
    if ($existing.Count -gt 0) {
        if ($existing.Count -ne 1 -or -not $existing[0].journal_state.ContainsKey('legacy_issue') -or
            ($existing[0].manifest.request.source_prs -join ',') -cne ($numbers -join ',')) {
            throw 'Legacy state overlaps a different registered cohort.'
        }
        $prior = $existing[0].journal_state
        if ($State.schema -eq 1 -and ($prior.cohort.members[0].source_sha -cne $State.source_sha -or
            $prior.release.target -cne $State.target)) { throw 'Legacy source proof changed.' }
        if ($State.schema -eq 2 -and (Get-BackportBatchMarker $State) -cne
            (Get-BackportBatchMarker (Read-BackportBatchMarker (Invoke-BackportApi "repos/$repository/issues/$($prior.legacy_issue)").body))) {
            throw 'Legacy prepared cohort differs from its original tracking record.'
        }
        Publish-BackportMilestone $prior $StatePath $BotLogin
        return
    }
    if ($State.schema -eq 1) {
        $source = Get-BackportSource $repository $State.source_pr
        if ($source.merge_commit_sha -cne $State.source_sha) { throw 'Source SHA changed.' }
        $tracking = Get-BackportTracking $repository $State.source_pr
        $pull = Get-BackportPull $repository $State.source_pr $State.target
        if ($null -ne $tracking) { Assert-BackportObject $tracking $State $BotLogin }
        if ($null -ne $pull) {
            if ($null -eq $tracking) { throw 'Legacy PR has no tracking identity.' }
            Assert-BackportObject $pull $State $BotLogin
            if ('ext-backport-processed' -notin @($source.labels | ForEach-Object { $_.name })) {
                Set-BackportProcessed $repository $State.source_pr
            }
            Write-BackportSummary "Retained legacy backport $($pull.html_url); legacy objects were not modified."
            return
        }
        if ($null -ne $tracking -and $State.result.outcome -ne 'applied') {
            Write-BackportSummary "Retained legacy tracking issue $($tracking.html_url); no replay."
            return
        }
        if ($null -ne $tracking -and $null -ne (Read-BackportPublicationIntent $tracking.body)) { throw 'Legacy publication is unconfirmed.' }
        $request = @{
            key = "single-$($State.source_pr)"; mode = 'single'; target = $State.target; team = ''
            batch_id = '0'; reference_time = $State.reference_time; manual = $State.manual
            source_prs = @($State.source_pr); sources = @(@{
                number = $State.source_pr; sha = $State.source_sha; merged_at = $source.merged_at
            })
        }
        if (-not $State.ContainsKey('main_team')) { $State.main_team = Get-BackportMainTeam $source }
        if ($State.ContainsKey('release')) { $request.release = $State.release }
        $cohort = @{
            schema = 2; repository = $repository; request = $request; members = @($State)
            target_sha = $State.result.target_sha; head = $State.result.commit; tree = $State.result.tree
        }
        if ($State.result.outcome -ne 'applied') {
            $cohort.head = $State.result.target_sha
            $cohort.tree = (Invoke-BackportGit (Join-Path (Split-Path -Parent $StatePath) 'git') @('rev-parse', "$($cohort.head)^{tree}")).text.Trim()
        }
    }
    elseif ($State.schema -eq 2) {
        $cohort = $State
        $matchingBatchRecords = @(Get-BackportBatchRecords $repository | Where-Object { $_.manifest.request.key -ceq $cohort.request.key })
        $tracking = if ($matchingBatchRecords.Count -eq 1) { $matchingBatchRecords[0].issue } else { $null }
        $pull = Get-BackportBatchPull $repository -Branch (Get-BackportCohortBranch $cohort)
        if ($null -ne $tracking) { Assert-BackportBatchObject $tracking $cohort $BotLogin }
        if ($null -ne $pull) {
            if ($null -eq $tracking) { throw 'Legacy PR has no tracking identity.' }
            Assert-BackportBatchObject $pull $cohort $BotLogin
            foreach ($member in @($cohort.members | Where-Object { $_.result.outcome -eq 'applied' })) {
                $source = Get-BackportSource $repository $member.source_pr
                if ($source.merge_commit_sha -cne $member.source_sha) { throw 'Legacy source SHA changed.' }
            }
            foreach ($member in @($cohort.members | Where-Object { $_.result.outcome -eq 'applied' })) {
                $source = Get-BackportSource $repository $member.source_pr
                if ('ext-backport-processed' -notin @($source.labels | ForEach-Object { $_.name })) {
                    Set-BackportProcessed $repository $member.source_pr
                }
            }
            Write-BackportSummary "Retained legacy backport $($pull.html_url); legacy objects were not modified."
            return
        }
        if ($null -ne $tracking -and $null -ne (Read-BackportPublicationIntent $tracking.body)) { throw 'Legacy publication is unconfirmed.' }
        foreach ($member in $cohort.members) { $member.main_team = Get-BackportMainTeam (Get-BackportSource $repository $member.source_pr) }
    }
    else { throw 'Unsupported publication state.' }
    $release = if ($State.schema -eq 1 -and $State.ContainsKey('release')) { $State.release }
        elseif ($cohort.request.ContainsKey('release')) { $cohort.request.release }
        else { Get-BackportRelease $repository $cohort.request.target }
    $wrapped = @{ schema = 3; repository = $repository; cohort = $cohort; release = $release }
    if ($null -ne $tracking) {
        $wrapped.legacy_issue = $tracking.number
        if ($State.schema -eq 1) { $cohort.branch = Get-BackportBranch $State.source_pr $State.target }
    }
    elseif (-not $cohort.ContainsKey('branch')) {
        Assert-BackportRelease $release $repository -Current
        $directory = Join-Path (Split-Path -Parent $StatePath) 'git'
        $cohort.branch = New-BackportCohortBranch $repository $directory $cohort.request @(Get-BackportBatchRecords $repository)
    }
    Assert-BackportJournalState $wrapped
    $wrapped | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
    Publish-BackportMilestone $wrapped $StatePath $BotLogin
}

Export-ModuleMember -Function Find-ExtRequestBackport, New-ExtRequestBackport, Publish-ExtRequestBackport,
    Find-ExtRequestBackportBatches, New-ExtRequestBackportBatch, Publish-ExtRequestBackportBatch
