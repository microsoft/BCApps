$script:TeamLabels = @('Finance', 'SCM', 'Integration', 'Other')
$script:ManualLabel = 'Ownership: Manual'
$script:ReviewLabel = 'Ownership: Needs Review'
$script:ConfidenceValues = @('high', 'medium', 'low')
$script:SourceValues = @(
    'issue:path',
    'issue:localization',
    'issue:title-object',
    'issue:title-phrase',
    'issue:app-area',
    'issue:body-object',
    'issue:unresolved',
    'pull_request:changed-files',
    'pull_request:ambiguous',
    'pull_request:unresolved',
    'pull_request:incomplete-files'
)
$script:EvidenceKinds = @('path', 'localization', 'object', 'app_area', 'changed_file', 'api')
$script:LabelDefinitions = @(
    [pscustomobject]@{ Name = 'Finance'; Color = '1d76db'; Description = 'Requests owned by the Finance team' },
    [pscustomobject]@{ Name = 'SCM'; Color = '60AFDE'; Description = 'Requests owned by the SCM team' },
    [pscustomobject]@{ Name = 'Integration'; Color = 'DC57FE'; Description = 'Requests owned by the Integration team' },
    [pscustomobject]@{ Name = 'Other'; Color = '6E7781'; Description = 'Requests not mapped to Finance, SCM, or Integration' },
    [pscustomobject]@{ Name = $script:ManualLabel; Color = 'FBCA04'; Description = 'Preserve the manually selected team ownership' },
    [pscustomobject]@{ Name = $script:ReviewLabel; Color = 'D93F0B'; Description = 'Ownership is Other, low confidence, or needs manual correction' }
)

function Get-TeamOwnershipConfiguration {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        TeamLabels      = @($script:TeamLabels)
        ManualLabel     = $script:ManualLabel
        ReviewLabel     = $script:ReviewLabel
        ConfidenceValues = @($script:ConfidenceValues)
        SourceValues    = @($script:SourceValues)
        EvidenceKinds   = @($script:EvidenceKinds)
        LabelDefinitions = @($script:LabelDefinitions)
    }
}

function Test-HasProperty {
    param(
        [AllowNull()]
        [object] $Object,
        [Parameter(Mandatory)]
        [string] $Name
    )

    return $null -ne $Object -and $null -ne $Object.PSObject -and $Object.PSObject.Properties.Name -ccontains $Name
}

function Assert-ObjectProperties {
    param(
        [Parameter(Mandatory)]
        [object] $Object,
        [Parameter(Mandatory)]
        [string[]] $Required,
        [Parameter(Mandatory)]
        [string[]] $Allowed,
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ($Object -is [string] -or $Object -is [System.Collections.IEnumerable]) {
        throw "$Path must be an object."
    }

    foreach ($name in $Required) {
        if (-not (Test-HasProperty -Object $Object -Name $name)) {
            throw "$Path.$name is required."
        }
    }

    foreach ($name in $Object.PSObject.Properties.Name) {
        if ($Allowed -cnotcontains $name) {
            throw "$Path.$name is not allowed by schema version 1."
        }
    }
}

function Assert-BoundedString {
    param(
        [AllowNull()]
        [object] $Value,
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [int] $MaximumLength
    )

    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) {
        throw "$Path must be a non-empty string."
    }

    if ($Value.Length -gt $MaximumLength) {
        throw "$Path exceeds the maximum length of $MaximumLength."
    }
}

function Test-PositiveInteger {
    param(
        [AllowNull()]
        [object] $Value
    )

    $isInteger = $Value -is [byte] -or
        $Value -is [int16] -or
        $Value -is [int32] -or
        $Value -is [int64] -or
        $Value -is [uint16] -or
        $Value -is [uint32] -or
        $Value -is [uint64]
    return $isInteger -and $Value -gt 0
}

function Assert-OwnershipResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Result,
        [Parameter(Mandatory)]
        [string] $ExpectedCorrelationToken,
        [Parameter(Mandatory)]
        [ValidateSet('issue', 'pull_request')]
        [string] $ExpectedSubjectKind,
        [Parameter(Mandatory)]
        [int] $ExpectedSubjectNumber,
        [string] $ExpectedRepository = 'microsoft/BCApps'
    )

    Assert-ObjectProperties -Object $Result `
        -Required @('schemaVersion', 'correlationToken', 'subject', 'ownership') `
        -Allowed @('schemaVersion', 'correlationToken', 'subject', 'ownership') `
        -Path 'result'

    if ($Result.schemaVersion -isnot [int] -and $Result.schemaVersion -isnot [long]) {
        throw 'result.schemaVersion must be an integer.'
    }
    if ($Result.schemaVersion -ne 1) {
        throw "Unsupported ownership schema version '$($Result.schemaVersion)'."
    }

    Assert-BoundedString -Value $Result.correlationToken -Path 'result.correlationToken' -MaximumLength 64
    if ($Result.correlationToken -cnotmatch '^[A-Za-z0-9._-]{1,64}$') {
        throw 'result.correlationToken has an invalid format.'
    }
    if ($Result.correlationToken -cne $ExpectedCorrelationToken) {
        throw 'Ownership result correlation token does not match this run.'
    }

    Assert-ObjectProperties -Object $Result.subject `
        -Required @('repository', 'kind', 'number') `
        -Allowed @('repository', 'kind', 'number') `
        -Path 'result.subject'

    if ($Result.subject.repository -isnot [string] -or $Result.subject.repository -cne $ExpectedRepository) {
        throw 'Ownership result repository identity does not match.'
    }
    if ($Result.subject.kind -isnot [string] -or $Result.subject.kind -cne $ExpectedSubjectKind) {
        throw 'Ownership result subject kind does not match.'
    }
    if (-not (Test-PositiveInteger -Value $Result.subject.number) -or
        [int64]$Result.subject.number -ne $ExpectedSubjectNumber) {
        throw 'Ownership result subject number does not match.'
    }

    Assert-ObjectProperties -Object $Result.ownership `
        -Required @('team', 'source', 'reason', 'confidence', 'evidence') `
        -Allowed @('team', 'source', 'reason', 'confidence', 'evidence') `
        -Path 'result.ownership'

    if ($Result.ownership.team -isnot [string] -or $script:TeamLabels -cnotcontains $Result.ownership.team) {
        throw "Invalid ownership team '$($Result.ownership.team)'."
    }
    if ($Result.ownership.source -isnot [string] -or $script:SourceValues -cnotcontains $Result.ownership.source) {
        throw "Invalid ownership source '$($Result.ownership.source)'."
    }
    Assert-BoundedString -Value $Result.ownership.reason -Path 'result.ownership.reason' -MaximumLength 2000
    if ($Result.ownership.confidence -isnot [string] -or
        $script:ConfidenceValues -cnotcontains $Result.ownership.confidence) {
        throw "Invalid ownership confidence '$($Result.ownership.confidence)'."
    }
    if ($null -eq $Result.ownership.evidence -or $Result.ownership.evidence -is [string] -or
        $Result.ownership.evidence -isnot [System.Collections.IEnumerable]) {
        throw 'result.ownership.evidence must be an array.'
    }

    $evidence = @($Result.ownership.evidence)
    if ($evidence.Count -gt 100) {
        throw 'result.ownership.evidence exceeds 100 entries.'
    }

    for ($index = 0; $index -lt $evidence.Count; $index++) {
        $item = $evidence[$index]
        $path = "result.ownership.evidence[$index]"
        Assert-ObjectProperties -Object $item `
            -Required @('kind', 'value', 'team') `
            -Allowed @('kind', 'value', 'team', 'path', 'previousPath', 'status', 'category') `
            -Path $path

        if ($item.kind -isnot [string] -or $script:EvidenceKinds -cnotcontains $item.kind) {
            throw "Invalid evidence kind '$($item.kind)' at $path."
        }
        Assert-BoundedString -Value $item.value -Path "$path.value" -MaximumLength 4096

        if ($null -ne $item.team -and
            ($item.team -isnot [string] -or $script:TeamLabels -cnotcontains $item.team)) {
            throw "Invalid evidence team '$($item.team)' at $path."
        }

        foreach ($optionalName in @('path', 'previousPath', 'status', 'category')) {
            if (Test-HasProperty -Object $item -Name $optionalName) {
                Assert-BoundedString -Value $item.$optionalName -Path "$path.$optionalName" -MaximumLength 4096
            }
        }
    }

    return [pscustomobject]@{
        Team       = $Result.ownership.team
        Source     = $Result.ownership.source
        Reason     = $Result.ownership.reason.Trim()
        Confidence = $Result.ownership.confidence
        Evidence   = $evidence
    }
}

function Test-LabelName {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $LabelNames,
        [Parameter(Mandatory)]
        [string] $Expected
    )

    return @($LabelNames | Where-Object { $_ -ieq $Expected }).Count -gt 0
}

function Get-OwnershipLabelState {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()]
        [string[]] $LabelNames = @()
    )

    $selectedTeams = @($script:TeamLabels | Where-Object { Test-LabelName -LabelNames $LabelNames -Expected $_ })
    return [pscustomobject]@{
        TeamLabels        = $selectedTeams
        TeamCount         = $selectedTeams.Count
        SelectedTeam      = if ($selectedTeams.Count -eq 1) { $selectedTeams[0] } else { $null }
        HasManualOverride = Test-LabelName -LabelNames $LabelNames -Expected $script:ManualLabel
        NeedsReview       = Test-LabelName -LabelNames $LabelNames -Expected $script:ReviewLabel
    }
}

function Get-OwnershipMutationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Finance', 'SCM', 'Integration', 'Other')]
        [string] $SelectedTeam,
        [Parameter(Mandatory)]
        [ValidateSet('high', 'medium', 'low')]
        [string] $Confidence,
        [AllowEmptyCollection()]
        [string[]] $CurrentLabels = @()
    )

    $state = Get-OwnershipLabelState -LabelNames $CurrentLabels
    if ($state.HasManualOverride) {
        throw 'Ownership labels cannot be planned while the manual override is present.'
    }

    $add = [System.Collections.Generic.List[string]]::new()
    $remove = [System.Collections.Generic.List[string]]::new()

    if (-not (Test-LabelName -LabelNames $CurrentLabels -Expected $SelectedTeam)) {
        $add.Add($SelectedTeam)
    }
    foreach ($team in $state.TeamLabels) {
        if ($team -cne $SelectedTeam) {
            $remove.Add($team)
        }
    }

    $shouldReview = $SelectedTeam -ceq 'Other' -or $Confidence -ceq 'low'
    if ($shouldReview -and -not $state.NeedsReview) {
        $add.Add($script:ReviewLabel)
    } elseif (-not $shouldReview -and $state.NeedsReview) {
        $remove.Add($script:ReviewLabel)
    }

    return [pscustomobject]@{
        Add               = @($add)
        Remove            = @($remove)
        SelectedTeam      = $SelectedTeam
        ShouldReview      = $shouldReview
        AlreadyConverged  = $add.Count -eq 0 -and $remove.Count -eq 0 -and
            $state.TeamCount -eq 1 -and $state.SelectedTeam -ceq $SelectedTeam
    }
}

function Get-OwnershipEventOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('issues', 'pull_request_target')]
        [string] $EventName,
        [Parameter(Mandatory)]
        [string] $Action,
        [AllowNull()]
        [string] $LabelName,
        [bool] $HasManualOverride
    )

    $contentActions = if ($EventName -ceq 'issues') {
        @('opened', 'reopened', 'edited')
    } else {
        @('opened', 'reopened', 'edited', 'synchronize', 'ready_for_review')
    }

    if ($contentActions -ccontains $Action) {
        return 'classify'
    }
    if (@('labeled', 'unlabeled') -cnotcontains $Action) {
        return 'ignore'
    }

    if ($LabelName -ieq $script:ManualLabel) {
        if ($Action -ceq 'unlabeled') {
            return 'classify'
        }
        return 'audit'
    }
    if (@($script:TeamLabels | Where-Object { $_ -ieq $LabelName }).Count -gt 0) {
        if ($HasManualOverride) {
            return 'audit'
        }
        return 'ignore'
    }
    return 'ignore'
}

function Get-OwnershipSubjectFromEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('issues', 'pull_request_target')]
        [string] $EventName,
        [Parameter(Mandatory)]
        [object] $EventPayload
    )

    $subject = if ($EventName -ceq 'issues') { $EventPayload.issue } else { $EventPayload.pull_request }
    if ($null -eq $subject -or -not (Test-PositiveInteger -Value $subject.number)) {
        throw "The $EventName event does not contain a valid subject number."
    }
    if ($subject.state -cne 'open') {
        throw "The $EventName subject is not open."
    }

    return [pscustomobject]@{
        Kind   = if ($EventName -ceq 'issues') { 'issue' } else { 'pull_request' }
        Number = [int]$subject.number
    }
}

function Assert-ReconciliationLimit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int] $Limit
    )

    if ($Limit -lt 1 -or $Limit -gt 100) {
        throw 'Reconciliation limit must be between 1 and 100.'
    }
    return $Limit
}

function Get-NextReconciliationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('issue', 'pull_request')]
        [string] $CurrentKind,
        [AllowNull()]
        [string] $EndCursor,
        [Parameter(Mandatory)]
        [bool] $HasNextPage
    )

    if ($HasNextPage) {
        if ([string]::IsNullOrWhiteSpace($EndCursor)) {
            throw 'A continuation cursor is required when another page exists.'
        }
        return [pscustomobject]@{ Kind = $CurrentKind; Cursor = $EndCursor }
    }

    return [pscustomobject]@{
        Kind   = if ($CurrentKind -ceq 'issue') { 'pull_request' } else { 'issue' }
        Cursor = $null
    }
}

function ConvertTo-OwnershipMatrixJson {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()]
        [object[]] $Subjects = @()
    )

    if ($Subjects.Count -eq 0) {
        return '[]'
    }
    return ConvertTo-Json -InputObject @($Subjects) -Compress
}

function Get-SafeOwnershipSummaryText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string] $Text,
        [int] $MaximumLength = 500
    )

    if ($null -eq $Text) {
        return ''
    }
    $safe = (($Text -replace '[\r\n]+', ' ') -replace '\|', '\|').Trim()
    if ($safe.Length -gt $MaximumLength) {
        return $safe.Substring(0, $MaximumLength)
    }
    return $safe
}

Export-ModuleMember -Function @(
    'Get-TeamOwnershipConfiguration',
    'Assert-OwnershipResult',
    'Get-OwnershipLabelState',
    'Get-OwnershipMutationPlan',
    'Get-OwnershipEventOperation',
    'Get-OwnershipSubjectFromEvent',
    'Assert-ReconciliationLimit',
    'Get-NextReconciliationState',
    'ConvertTo-OwnershipMatrixJson',
    'Get-SafeOwnershipSummaryText'
)
