[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Repository,
    [Parameter(Mandatory)]
    [ValidateSet('issue', 'pull_request')]
    [string] $SubjectKind,
    [Parameter(Mandatory)]
    [int] $Limit,
    [AllowEmptyString()]
    [string] $Cursor = '',
    [string] $StatePath = '',
    [switch] $Scheduled,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot 'TeamOwnership.psm1') -Force

function Write-JobSummary {
    param([Parameter(Mandatory)][string] $Text)

    Write-Host $Text
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

function Set-WorkflowOutput {
    param(
        [Parameter(Mandatory)][string] $Name,
        [AllowEmptyString()][string] $Value
    )

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "$Name=$Value"
    }
}

Assert-ReconciliationLimit -Limit $Limit | Out-Null

if ($Repository -cne 'microsoft/BCApps') {
    throw "Reconciliation is restricted to microsoft/BCApps."
}

if ($Scheduled -and -not [string]::IsNullOrWhiteSpace($StatePath) -and
    (Test-Path -LiteralPath $StatePath -PathType Leaf)) {
    $savedState = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (($savedState.schemaVersion -isnot [int] -and $savedState.schemaVersion -isnot [long]) -or
        $savedState.schemaVersion -ne 1 -or $savedState.kind -isnot [string] -or
        $savedState.kind -cnotin @('issue', 'pull_request') -or
        ($null -ne $savedState.cursor -and $savedState.cursor -isnot [string])) {
        throw 'The saved reconciliation checkpoint is invalid.'
    }
    $SubjectKind = [string]$savedState.kind
    $Cursor = if ($null -eq $savedState.cursor) { '' } else { [string]$savedState.cursor }
}

if ($Cursor.Length -gt 512 -or ($Cursor -ne '' -and $Cursor -notmatch '^[A-Za-z0-9+/=_-]+$')) {
    throw 'The reconciliation cursor has an invalid format.'
}

$nameParts = $Repository.Split('/', 2)
if ($nameParts.Count -ne 2) {
    throw "Repository '$Repository' must be in owner/name form."
}

$connectionName = if ($SubjectKind -ceq 'issue') { 'issues' } else { 'pullRequests' }
$query = @"
query(`$owner: String!, `$repo: String!, `$first: Int!, `$after: String) {
  repository(owner: `$owner, name: `$repo) {
    $connectionName(first: `$first, after: `$after, states: OPEN, orderBy: {field: CREATED_AT, direction: ASC}) {
      nodes {
        number
        labels(first: 100) {
          nodes { name }
          pageInfo { hasNextPage }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
"@

$arguments = @(
    'api', 'graphql',
    '-f', "query=$query",
    '-f', "owner=$($nameParts[0])",
    '-f', "repo=$($nameParts[1])",
    '-F', "first=$Limit"
)
if ($Cursor -ne '') {
    $arguments += @('-f', "after=$Cursor")
}

$raw = & gh @arguments
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to query the reconciliation batch from GitHub GraphQL.'
}
$response = $raw | ConvertFrom-Json -Depth 20
$connection = $response.data.repository.$connectionName
if ($null -eq $connection) {
    throw "GitHub returned no $connectionName connection."
}

$subjects = [System.Collections.Generic.List[object]]::new()
$exactOne = 0
$missing = 0
$conflicting = 0
$overridden = 0

foreach ($node in @($connection.nodes)) {
    if ($node.labels.pageInfo.hasNextPage) {
        throw "$SubjectKind #$($node.number) has more than 100 labels; override state cannot be evaluated safely."
    }

    $labelNames = @($node.labels.nodes | ForEach-Object { [string]$_.name })
    $state = Get-OwnershipLabelState -LabelNames $labelNames
    if ($state.TeamCount -eq 1) {
        $exactOne++
    } elseif ($state.TeamCount -eq 0) {
        $missing++
    } else {
        $conflicting++
    }
    if ($state.HasManualOverride) {
        $overridden++
    }

    $subjects.Add([pscustomobject]@{
        kind   = $SubjectKind
        number = [int]$node.number
    })
}

$next = Get-NextReconciliationState -CurrentKind $SubjectKind `
    -EndCursor $connection.pageInfo.endCursor `
    -HasNextPage ([bool]$connection.pageInfo.hasNextPage)
$matrix = ConvertTo-OwnershipMatrixJson -Subjects @($subjects)

Set-WorkflowOutput -Name 'matrix' -Value $matrix
Set-WorkflowOutput -Name 'has_items' -Value ($subjects.Count -gt 0).ToString().ToLowerInvariant()
Set-WorkflowOutput -Name 'next_kind' -Value $next.Kind
Set-WorkflowOutput -Name 'next_cursor' -Value $(if ($null -eq $next.Cursor) { '' } else { $next.Cursor })

if ($Scheduled -and -not $DryRun) {
    if ([string]::IsNullOrWhiteSpace($StatePath)) {
        throw 'A checkpoint path is required for scheduled reconciliation.'
    }
    $parent = Split-Path -Parent $StatePath
    if ($parent -ne '') {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [pscustomobject]@{
        schemaVersion = 1
        kind          = $next.Kind
        cursor        = $next.Cursor
    } | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding UTF8
}

$nextCursorDisplay = if ($null -eq $next.Cursor) { '(start)' } else { $next.Cursor }
Write-JobSummary @"
### Ownership reconciliation batch
| Count | Value |
| --- | ---: |
| Selected | $($subjects.Count) |
| Existing exact-one | $exactOne |
| Existing missing | $missing |
| Existing conflicting | $conflicting |
| Manual overrides | $overridden |
| Deferred by batch bound | $([bool]$connection.pageInfo.hasNextPage) |

Next position: ``$($next.Kind) / $nextCursorDisplay``. Dry run: **$($DryRun.IsPresent)**.
"@
