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
        $other.Count -eq 0 -and $Labels -notcontains 'ext-backporting'
}

function Test-BackportAutomaticSource {
    param([hashtable] $Source, [DateTimeOffset] $Now = [DateTimeOffset]::UtcNow)

    if ($null -eq $Source.merged_at -or $Source.base.ref -cne 'main') { return $false }
    $merged = [DateTimeOffset]$Source.merged_at
    return $merged -ge $Now.AddDays(-7) -and $merged -le $Now -and
        (Test-BackportCategory @($Source.labels | ForEach-Object { $_.name }))
}

function Find-ExtRequestBackport {
    [CmdletBinding()]
    param([string] $Repository, [string] $SourcePr = '', [string] $TargetOverride = '')

    Assert-BackportRepository $Repository
    $branches = @(Get-BackportApiPages "repos/$Repository/branches" | ForEach-Object { $_.name })
    $target = Get-BackportLatestTarget -Branches $branches -Override $TargetOverride
    if (-not [string]::IsNullOrWhiteSpace($SourcePr)) {
        if ($SourcePr -cnotmatch '^[1-9][0-9]{0,9}$') { throw 'source_pr must be a positive PR number.' }
        return @{ source_pr = [long]$SourcePr; target = $target }
    }

    $now = [DateTimeOffset]::UtcNow
    $sources = [Collections.Generic.List[object]]::new()
    for ($page = 1; ; $page++) {
        $items = @(Invoke-BackportApi "repos/$Repository/pulls?state=closed&base=main&sort=updated&direction=desc&per_page=100&page=$page")
        foreach ($source in $items) {
            if (Test-BackportAutomaticSource -Source $source -Now $now) { $sources.Add($source) }
        }
        if ($items.Count -lt 100 -or [DateTimeOffset]$items[-1].updated_at -lt $now.AddDays(-7)) { break }
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
    else { $PrLabels }
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
    param([string] $Directory, [string] $SourceSha, [string] $TargetSha)

    $parents = (Invoke-BackportGit $Directory @('rev-list', '--parents', '-n', '1', $SourceSha)).text.Trim().Split(' ')
    if ($parents.Count -ne 2) { throw 'Only squash-merged source PRs are supported.' }
    $raw = (Invoke-BackportGit $Directory @('diff', '--raw', '--no-abbrev', '--no-renames', '-z', $parents[1], $SourceSha)).text
    $paths = @(Assert-BackportPaths $raw)
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
    param([string] $Repository, [long] $SourcePr, [string] $Target, [bool] $Manual, [string] $StatePath)

    Assert-BackportRepository $Repository
    $source = Get-BackportSource $Repository $SourcePr
    $issues = @(Get-BackportSourceIssues $Repository $SourcePr)
    $labels = @(Get-BackportLabels -Issues $issues -PrLabels $source.labels)
    if (-not $Manual -and (-not (Test-BackportAutomaticSource $source) -or
        @($issues | Where-Object { -not (Test-BackportCategory @($_.labels.nodes | ForEach-Object { $_.name })) }).Count -gt 0)) {
        throw "Source PR #$SourcePr or one of its issues is no longer automatically eligible."
    }
    $tracking = Get-BackportTracking $Repository $SourcePr
    $target = Get-BackportPinnedTarget -Source $source -Tracking $tracking -Default $Target
    Assert-BackportTarget $target
    $pull = Get-BackportPull $Repository $SourcePr $target
    $result = @{ outcome = 'existing'; target_sha = $null; commit = $null; tree = $null; paths = @() }
    $directory = Join-Path (Split-Path -Parent $StatePath) 'git'
    if ($null -eq $pull) {
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
        result = $result
    }
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $StatePath) -Force
    $state | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $StatePath -Encoding utf8NoBOM
    $issueLinks = ($issues | ForEach-Object { $_.url }) -join ', '
    Write-BackportSummary "Main PR #$SourcePr -> $target`: **$($result.outcome)**. Source issues: $issueLinks"
}

function Get-BackportStatusLabel {
    param([string] $Status, [string] $Target)
    "ext-backport-$Status`:$(($Target -split '/')[1])"
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

function Add-BackportStatus {
    param([string] $Repository, [long] $SourcePr, [string] $Status, [string] $Target)

    $name = Get-BackportStatusLabel $Status $Target
    Ensure-BackportLabels $Repository @(@{ name = $name; color = 'C5DEF5'; description = 'Extensibility backport status.' })
    $null = Invoke-BackportApi "repos/$Repository/issues/$SourcePr/labels" -Method POST -Body @{ labels = @($name) }
}

function Remove-BackportIntents {
    param([string] $Repository, [long] $SourcePr, [string] $Target)

    $source = Get-BackportSource $Repository $SourcePr
    foreach ($status in @('pending', 'publishing', 'needs-attention')) {
        $label = Get-BackportStatusLabel $status $Target
        if ($label -in @($source.labels | ForEach-Object { $_.name })) {
            $null = Invoke-BackportApi "repos/$Repository/issues/$SourcePr/labels/$([uri]::EscapeDataString($label))" -Method DELETE
        }
    }
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
            "Fixes $repository#$TrackingNumber", '',
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
    $status = if ($null -ne $Pull.merged_at) { 'merged' } elseif ($Pull.state -eq 'closed') { 'needs-attention' } else { 'created' }
    Add-BackportStatus $repository $State.source_pr $status $State.target
    if ($status -ne 'needs-attention') { Remove-BackportIntents $repository $State.source_pr $State.target }
    if ($status -eq 'merged' -and $Tracking.state -ne 'closed') {
        $null = Invoke-BackportApi "repos/$repository/issues/$($Tracking.number)" -Method PATCH -Body @{ state = 'closed'; state_reason = 'completed' }
    }
    Write-BackportSummary "Main PR #$($State.source_pr): $($Pull.html_url) (**$status**); issue $($Tracking.html_url)."
}

function Publish-ExtRequestBackport {
    [CmdletBinding()]
    param([string] $StatePath, [string] $BotLogin)

    $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -AsHashtable -Depth 40
    if ($state.schema -ne 1 -or $BotLogin -cnotmatch '^[a-z0-9-]+\[bot\]$') { throw 'Invalid publication state or App identity.' }
    Assert-BackportRepository $state.repository
    Assert-BackportTarget $state.target
    $repository = $state.repository
    $source = Get-BackportSource $repository $state.source_pr
    if ($source.merge_commit_sha -cne $state.source_sha) { throw 'Source merge identity changed.' }
    if (-not $state.manual -and -not (Test-BackportAutomaticSource $source)) { throw 'Automatic source eligibility changed before publication.' }
    $state.issues = @(Get-BackportSourceIssues $repository $state.source_pr)
    if (-not $state.manual -and @($state.issues | Where-Object {
        -not (Test-BackportCategory @($_.labels.nodes | ForEach-Object { $_.name }))
    }).Count -gt 0) { throw 'A source issue is no longer automatically eligible.' }
    $state.labels = @(Get-BackportLabels -Issues $state.issues -PrLabels $source.labels)
    $tracking = Get-BackportTracking $repository $state.source_pr
    if ($null -ne $tracking) { Assert-BackportObject $tracking $state $BotLogin }
    $pull = Get-BackportPull $repository $state.source_pr $state.target
    if ($null -ne $pull) {
        if ($null -eq $tracking) { throw 'Existing backport PR has no tracking issue; reconcile manually.' }
        Complete-BackportPull $state $tracking $pull $BotLogin
        return
    }
    $labelsOnSource = @($source.labels | ForEach-Object { $_.name })
    if ((Get-BackportStatusLabel publishing $state.target) -in $labelsOnSource) {
        throw 'A previous PR creation is unconfirmed. Inspect closed/open PRs before clearing the publishing label.'
    }
    if ($null -eq $tracking -and @($labelsOnSource | Where-Object { $_ -like 'ext-backport-*' }).Count -gt 0) {
        throw 'Source has prior backport state but no tracking issue. Reconcile manually; do not create a duplicate.'
    }
    if ($null -ne $tracking -and ($tracking.state -eq 'closed' -or
        (-not $state.manual -and (Get-BackportStatusLabel needs-attention $state.target) -in $labelsOnSource))) {
        Write-BackportSummary "Main PR #$($state.source_pr): retained tracking issue $($tracking.html_url); manual attention is required."
        return
    }
    if ($state.result.outcome -notin @('applied', 'conflict', 'already-present')) { throw 'No publishable preparation result.' }
    Ensure-BackportLabels $repository $state.labels
    if ($null -eq $tracking) {
        # A durable intent makes an uncertain POST fail closed on later runs.
        Add-BackportStatus $repository $state.source_pr pending $state.target
        $title = "[Backport $(($state.target -split '/')[1])] #$($state.source_pr): $($state.source_title -replace '[\r\n]', ' ')"
        if ($title.Length -gt 240) { $title = $title.Substring(0, 240) }
        $tracking = Invoke-BackportApi "repos/$repository/issues" -Method POST -Body @{
            title = $title; body = Get-BackportBody $state; type = 'Task'
            labels = @($state.labels | ForEach-Object { $_.name })
        }
        $tracking = Invoke-BackportApi "repos/$repository/issues/$($tracking.number)"
        Assert-BackportObject $tracking $state $BotLogin
    }
    if ($state.result.outcome -eq 'conflict') {
        Add-BackportStatus $repository $state.source_pr needs-attention $state.target
        Write-BackportSummary "Conflict for main PR #$($state.source_pr); manual backport tracked at $($tracking.html_url)."
        return
    }
    if ($state.result.outcome -eq 'already-present') {
        Add-BackportStatus $repository $state.source_pr already-present $state.target
        $null = Invoke-BackportApi "repos/$repository/issues/$($tracking.number)" -Method PATCH -Body @{ state = 'closed'; state_reason = 'completed' }
        Remove-BackportIntents $repository $state.source_pr $state.target
        Write-BackportSummary "Main PR #$($state.source_pr) is already present; closed $($tracking.html_url) without an empty PR."
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
    Add-BackportStatus $repository $state.source_pr publishing $state.target
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

function Sync-ExtRequestBackport {
    [CmdletBinding()]
    param([string] $Repository, [string] $BotLogin)

    Assert-BackportRepository $Repository
    foreach ($tracking in @(Get-BackportApiPages "repos/$Repository/issues?state=open&labels=ext-backporting")) {
        if ($tracking.ContainsKey('pull_request')) { continue }
        $marker = Read-BackportMarker $tracking.body
        if ($null -eq $marker) { continue }
        $state = @{ repository = $Repository; source_pr = $marker.source_pr; source_sha = $marker.sha; target = $marker.target }
        Assert-BackportObject $tracking $state $BotLogin
        $pull = Get-BackportPull $Repository $marker.source_pr $marker.target
        if ($null -ne $pull) { Complete-BackportPull $state $tracking $pull $BotLogin }
    }
}

Export-ModuleMember -Function Find-ExtRequestBackport, New-ExtRequestBackport, Publish-ExtRequestBackport, Sync-ExtRequestBackport
