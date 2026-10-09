Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')

function Assert-ExpandedSettingsJson {
    <#.SYNOPSIS
    Rejects duplicate JSON keys and validates the settings with AL-Go's plain parser.
    #>
    param([Parameter(Mandatory)][string]$Json)
    $document = [System.Text.Json.JsonDocument]::Parse($Json)
    function Test-ObjectKey($Element) {
        if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
            $keys = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach ($property in $Element.EnumerateObject()) {
                if (-not $keys.Add($property.Name)) { throw "Ambiguous settings key: $($property.Name)." }
                Test-ObjectKey $property.Value
            }
        } elseif ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
            foreach ($item in $Element.EnumerateArray()) { Test-ObjectKey $item }
        }
    }
    try { Test-ObjectKey $document.RootElement } finally { $document.Dispose() }
    # This is deliberately the consumer's plain parser, not -AsHashtable.
    $null = $Json | ConvertFrom-Json -ErrorAction Stop
}

function Read-ExpandedSettings {
    <#.SYNOPSIS
    Reads one unambiguous AL-Go settings document.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Settings names one AL-Go document.')]
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $json = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    Assert-ExpandedSettingsJson -Json $json
    $json | ConvertFrom-Json -AsHashtable
}

function Write-ExpandedSettings {
    <#.SYNOPSIS
    Validates a complete settings document before emitting any bytes.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Settings names one AL-Go document.')]
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Settings, [Parameter(Mandatory)][string]$Path)
    $json = $Settings | ConvertTo-Json -Depth 30
    Assert-ExpandedSettingsJson -Json $json
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Set-ExpandedProjectSettings {
    <#.SYNOPSIS
    Generates the disposable diagnostic lane or producer project settings.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Settings names one AL-Go document.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Exact opt-in caller owns the disposable project; partial generation is not supported.')]
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [ValidateSet('Build', 'Lane')][string]$Kind,
        [Parameter(Mandatory)][string]$Country, [Parameter(Mandatory)][string]$Artifact, $Context)
    $settings = Read-ExpandedSettings -Path $Path
    $settings.projectName = "Expanded $Kind $Country"
    $settings.country = $Country.ToLowerInvariant()
    $settings.bcContainerHelperVersion = (Get-ExpandedApiPinSet).helper
    $settings.artifact = $Artifact
    $settings.skipUpgrade = $true
    $settings.incrementalBuilds = @{ onPush = $false; onPull_Request = $false; onSchedule = $false; retentionDays = 14; mode = 'modifiedApps' }
    $settings.maxTestAppReruns = 0
    $settings.doNotRunTests = ($Kind -eq 'Build')
    $settings.doNotPublishApps = ($Kind -eq 'Build')
    $settings.useCompilerFolder = ($Kind -eq 'Build')
    $settings.workspaceCompilation = @{ enabled = ($Kind -eq 'Build'); parallelism = 2 }
    if ($Kind -eq 'Lane') {
        $keys = @($settings.Keys | Where-Object { $_ -ieq 'conditionalSettings' })
        if ($keys.Count -gt 1) { throw 'Ambiguous conditional settings keys.' }
        if ($keys.Count) { $settings.Remove($keys[0]) }
        $settings['conditionalSettings'] = @()
        $settings.appFolders = @()
        $settings.testFolders = @()
        # AL-Go91b96 otherwise exits before consuming installTestAppsJson.
        $settings.projectsToTest = @("build/projects/Apps $Country")
        $settings.runTestsInAllInstalledTestApps = $true
        $settings.enableCleanTestCodeunitExecution = $true
        $settings.numberOfTenantsForTesting = $Context.cell.configuration.mounts.Count
        $settings.testType = $Context.lane.settings.testType
        $settings.companyName = $Context.lane.settings.company
        $settings.enableTaskScheduler = $Context.lane.settings.taskScheduler
        $settings.additionalDemoDataTypes = @()
        if ($Context.lane.id -like 'LegacyTestsBucket*') { $settings.bucketNumber = $Context.lane.settings.bucket }
        if ($Context.lane.id -eq 'LegacyTestsBucket1') { $settings.additionalDemoDataTypes = @('Standard', 'Evaluation') }
    }
    Write-ExpandedSettings -Settings $settings -Path $Path
}

function Set-ExpandedRepoSettings {
    <#.SYNOPSIS
    Pins a disposable diagnostic checkout's repository settings.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Settings names one AL-Go document.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Exact opt-in caller owns the disposable checkout; partial generation is not supported.')]
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [ValidateSet('Build', 'Lane')][string]$Kind,
        [Parameter(Mandatory)][string]$Country)
    $repo = Read-ExpandedSettings -Path $Path
    $pins = Get-ExpandedApiPinSet
    $repo.bcContainerHelperVersion = $pins.helper
    $repo.artifact = "https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/sandbox/$($pins.application)/$($Country.ToLowerInvariant())"
    $repo.maxTestAppReruns = 0
    $repo.workspaceCompilation = @{ enabled = ($Kind -eq 'Build'); parallelism = 2 }
    $repo.incrementalBuilds = @{ onPush = $false; onPull_Request = $false; onSchedule = $false; retentionDays = 14; mode = 'modifiedApps' }
    $repo.skipUpgrade = $true
    Write-ExpandedSettings -Settings $repo -Path $Path
    $repo
}

Export-ModuleMember -Function Assert-ExpandedSettingsJson, Read-ExpandedSettings, Write-ExpandedSettings, Set-ExpandedProjectSettings, Set-ExpandedRepoSettings
