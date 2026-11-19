[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Repository,

    [Parameter(Mandatory = $true)]
    [ValidateSet('all', 'Finance', 'SCM', 'Integrations')]
    [string] $Team,

    [ValidateRange(1, 100)]
    [int] $Limit = 5,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$teamLabels = @{
    Finance = 'Team: Finance'
    SCM = 'Team: SCM'
    Integrations = 'Team: Integrations'
}
$knownTeamLabels = @('Team: Finance', 'Team: SCM', 'Team: Integrations', 'Team: Other')
$requestLabels = @('event-request', 'request-for-external', 'enum-request', 'extensibility-enhancement')
$batchRequestLabels = @('event-request', 'request-for-external')

function Invoke-NativeText {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command,
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $AllowFailure
    )

    $output = & $Command @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "$Command $($Arguments -join ' ') failed: $text"
    }
    if ($AllowFailure) {
        $global:LASTEXITCODE = 0
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = $text
    }
}

function Get-IssueType {
    param([Parameter(Mandatory = $true)][long] $IssueNumber)

    $parts = $Repository.Split('/', 2)
    $query = 'query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){issueType{name}}}}'
    $response = Invoke-NativeText -Command 'gh' -Arguments @(
        'api', 'graphql',
        '-f', "query=$query",
        '-f', "owner=$($parts[0])",
        '-f', "repo=$($parts[1])",
        '-F', "number=$IssueNumber"
    )
    $issueType = (ConvertFrom-Json $response.Text).data.repository.issue.issueType
    if ($null -eq $issueType) {
        return $null
    }
    return $issueType.name
}

function Test-HasOpenPullRequest {
    param([Parameter(Mandatory = $true)][object] $Issue)

    foreach ($reference in @($Issue.closedByPullRequestsReferences)) {
        $referenceRepository = "$($reference.repository.owner.login)/$($reference.repository.name)"
        $response = Invoke-NativeText -Command 'gh' -Arguments @(
            'pr', 'view', "$($reference.number)",
            '--repo', $referenceRepository,
            '--json', 'state'
        ) -AllowFailure
        if ($response.ExitCode -ne 0) {
            Write-Warning "Unable to verify pull request #$($reference.number); skipping issue #$($Issue.number) to avoid duplicate implementation."
            return $true
        }
        if ((ConvertFrom-Json $response.Text).state -eq 'OPEN') {
            return $true
        }
    }

    return $false
}

function Test-IssueEligible {
    param(
        [Parameter(Mandatory = $true)][object] $Issue,
        [Parameter(Mandatory = $true)][string] $ExpectedTeamLabel
    )

    $labels = @($Issue.labels | ForEach-Object { $_.name })
    $assignedTeams = @($labels | Where-Object { $_ -in $knownTeamLabels })
    $assignedRequestTypes = @($labels | Where-Object { $_ -in $requestLabels })

    if ($assignedTeams.Count -ne 1 -or $assignedTeams[0] -ne $ExpectedTeamLabel) {
        return $false
    }
    if ($assignedRequestTypes.Count -ne 1 -or $assignedRequestTypes[0] -in $batchRequestLabels) {
        return $false
    }
    if ((Get-IssueType -IssueNumber $Issue.number) -ne 'Task') {
        return $false
    }

    return -not (Test-HasOpenPullRequest -Issue $Issue)
}

$selectedTeams = if ($Team -eq 'all') { @('Finance', 'SCM', 'Integrations') } else { @($Team) }
$matrix = [System.Collections.Generic.List[object]]::new()

foreach ($selectedTeam in $selectedTeams) {
    $teamLabel = $teamLabels[$selectedTeam]
    $response = Invoke-NativeText -Command 'gh' -Arguments @(
        'issue', 'list',
        '--repo', $Repository,
        '--state', 'open',
        '--label', 'ext-ready-to-implement',
        '--label', $teamLabel,
        '--limit', '1000',
        '--json', 'number,url,updatedAt,labels,closedByPullRequestsReferences'
    )

    foreach ($issue in @($response.Text | ConvertFrom-Json)) {
        if (Test-IssueEligible -Issue $issue -ExpectedTeamLabel $teamLabel) {
            $requestType = [string](
                $issue.labels |
                    ForEach-Object { $_.name } |
                    Where-Object { $_ -in $requestLabels } |
                    Select-Object -First 1
            )
            $matrix.Add(@{
                issue_number = [long]$issue.number
                issue_url = [string]$issue.url
                updated_at = [string]$issue.updatedAt
                request_type = $requestType
                team_label = $teamLabel
                team = $selectedTeam
            })
        }
    }
}

$selectedIssues = @($matrix | Sort-Object updated_at, issue_number | Select-Object -First $Limit)
@{ include = $selectedIssues } |
    ConvertTo-Json -Depth 5 -Compress |
    Set-Content -Path $OutputPath -Encoding UTF8

$global:LASTEXITCODE = 0
