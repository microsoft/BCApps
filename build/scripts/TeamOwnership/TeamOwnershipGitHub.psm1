function Invoke-OwnershipGh {
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments,
        [switch] $AllowNotFound
    )

    $output = & gh @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        $message = ($output | Out-String).Trim()
        if ($AllowNotFound -and $message -match '(?i)(HTTP 404|Not Found)') {
            return $null
        }
        throw "gh $($Arguments -join ' ') failed: $message"
    }
    return ($output | Out-String).Trim()
}

function Get-GitHubSubjectLabelNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Repository,
        [Parameter(Mandatory)]
        [int] $SubjectNumber
    )

    $raw = Invoke-OwnershipGh -Arguments @(
        'api', '--paginate', '--slurp',
        "repos/$Repository/issues/$SubjectNumber/labels?per_page=100"
    )
    $pages = $raw | ConvertFrom-Json -Depth 10
    $names = [System.Collections.Generic.List[string]]::new()
    foreach ($page in @($pages)) {
        foreach ($label in @($page)) {
            if ($null -ne $label.name) {
                $names.Add([string]$label.name)
            }
        }
    }
    return @($names)
}

function Add-GitHubSubjectLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Repository,
        [Parameter(Mandatory)]
        [int] $SubjectNumber,
        [Parameter(Mandatory)]
        [string] $Label
    )

    Invoke-OwnershipGh -Arguments @(
        'api', '-X', 'POST',
        "repos/$Repository/issues/$SubjectNumber/labels",
        '-f', "labels[]=$Label",
        '--silent'
    ) | Out-Null
}

function Remove-GitHubSubjectLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Repository,
        [Parameter(Mandatory)]
        [int] $SubjectNumber,
        [Parameter(Mandatory)]
        [string] $Label
    )

    $encodedLabel = [uri]::EscapeDataString($Label)
    Invoke-OwnershipGh -Arguments @(
        'api', '-X', 'DELETE',
        "repos/$Repository/issues/$SubjectNumber/labels/$encodedLabel",
        '--silent'
    ) -AllowNotFound | Out-Null
}

function Set-GitHubOwnershipLabels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Repository,
        [Parameter(Mandatory)]
        [object[]] $Definitions
    )

    $raw = Invoke-OwnershipGh -Arguments @(
        'api', '--paginate', '--slurp',
        "repos/$Repository/labels?per_page=100"
    )
    $pages = $raw | ConvertFrom-Json -Depth 10
    $existing = @{}
    foreach ($page in @($pages)) {
        foreach ($label in @($page)) {
            if ($null -ne $label.name) {
                $existing[[string]$label.name] = $label
            }
        }
    }

    foreach ($definition in $Definitions) {
        $match = $existing.Keys | Where-Object { $_ -ieq $definition.Name } | Select-Object -First 1
        if ($null -eq $match) {
            Invoke-OwnershipGh -Arguments @(
                'api', '-X', 'POST',
                "repos/$Repository/labels",
                '-f', "name=$($definition.Name)",
                '-f', "color=$($definition.Color)",
                '-f', "description=$($definition.Description)",
                '--silent'
            ) | Out-Null
            continue
        }

        $current = $existing[$match]
        if ($current.name -cne $definition.Name -or
            $current.color -cne $definition.Color -or
            $current.description -cne $definition.Description) {
            $encodedName = [uri]::EscapeDataString([string]$current.name)
            Invoke-OwnershipGh -Arguments @(
                'api', '-X', 'PATCH',
                "repos/$Repository/labels/$encodedName",
                '-f', "new_name=$($definition.Name)",
                '-f', "color=$($definition.Color)",
                '-f', "description=$($definition.Description)",
                '--silent'
            ) | Out-Null
        }
    }
}

Export-ModuleMember -Function @(
    'Get-GitHubSubjectLabelNames',
    'Add-GitHubSubjectLabel',
    'Remove-GitHubSubjectLabel',
    'Set-GitHubOwnershipLabels'
)
