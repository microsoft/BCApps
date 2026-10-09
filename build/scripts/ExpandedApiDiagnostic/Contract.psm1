Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\AppPublicationPolicy.psm1')

function Assert-ExpandedInstalledInventory {
    param([Parameter(Mandatory)][array]$Files, [Parameter(Mandatory)][AllowEmptyCollection()][array]$Installed)
    $standard = @(Get-StandardAppPublicationExclusion)
    $required = @()
    $excluded = @()
    foreach ($file in $Files) {
        $baseName = [IO.Path]::GetFileNameWithoutExtension($file.path)
        if (Test-AppPublicationExcluded -BaseName $baseName -ExclusionList $standard) {
            if ($file.appName -cnotin $standard) { throw 'Excluded filename does not match standard library metadata.' }
            if (@($Installed | Where-Object { [string]$_.AppId -eq [string]$file.appId }).Count) {
                throw "Repository-standard excluded library unexpectedly installed: $($file.appName)."
            }
            $excluded += $file
        } else {
            $installedMatch = @($Installed | Where-Object {
                [string]$_.AppId -eq [string]$file.appId -and [string]$_.Version -eq $file.version
            })
            if ($installedMatch.Count -ne 1) { throw "Installed package/version mismatch for $($file.appName)." }
            $required += $file
        }
    }
    @{ required = $required; excluded = $excluded; standardExclusions = $standard
        installed = @($Installed | Select-Object AppId, Name, Version, Publisher) }
}

function Get-ExpandedApiPinSet {
    @{
        baseline = '97c2f034e7a32eb3bbb7efb1a1e893ea06ac121b'
        stack = 'f6c91f21b7fac7942c9d2dcd589a33c1b1b604c7'
        pilot = '94989d1c434f264f688748143eadc915a7b2a706'
        pilotRun = '37758493320'
        platform = '30.0.55665.0'
        application = '30.0.55683.0'
        helper = '6.1.19-preview2811389'
        alGo = '91b96c2b294be6f823277dafe6f03350abfb9d23'
        image = 'mcr.microsoft.com/businesscentral@sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492'
        memoryBytes = 17179869184L
        authentication = 'existing-container-password-file'
    }
}

function Assert-ExpandedApiDispatch {
    if ($env:GITHUB_REPOSITORY -cne 'microsoft/BCApps' -or
        $env:GITHUB_REF -cne 'refs/heads/features/653393-expanded-api-diagnostic' -or
        $env:GITHUB_EVENT_NAME -cne 'workflow_dispatch' -or
        $env:GITHUB_RUN_ATTEMPT -cne '1' -or $env:GITHUB_RUN_ID -notmatch '^\d{1,20}$') {
        throw 'Expanded API diagnostics require their exact opt-in branch, manual event and original attempt.'
    }
}

function Get-ExpandedApiPlan {
    param([Parameter(Mandatory)][string]$InventoryPath)
    $inventory = Get-Content -LiteralPath $InventoryPath -Raw | ConvertFrom-Json
    $pins = Get-ExpandedApiPinSet
    if ($inventory.stackTip -cne $pins.stack -or $inventory.runtimeVerified -ne $false -or
        @($inventory.routes).Count -ne 167 -or
        @($inventory.routes.appId | Sort-Object -Unique).Count -ne 15) {
        throw 'The reviewed 167-variant / 15-app static inventory is required; it is not runtime evidence.'
    }
    $laneSettings = @{
        Default = @{ testType = 'UnitTest'; company = 'Empty Company'; taskScheduler = $false }
        IntegrationTests = @{ testType = 'IntegrationTest'; company = 'My Company'; taskScheduler = $false }
        UncategorizedTests = @{ testType = 'Uncategorized'; company = 'CRONUS International Ltd.'; taskScheduler = $true }
        LegacyTestsBucket1 = @{ testType = 'Legacy'; company = 'CRONUS International Ltd.'; taskScheduler = $false; bucket = 1; additionalDemoDataTypes = @('Standard', 'Evaluation') }
        LegacyTestsBucket2 = @{ testType = 'Legacy'; company = 'CRONUS International Ltd.'; taskScheduler = $false; bucket = 2 }
    }
    $configurations = @(
        @{ id = 'm1w1'; mounts = @('default'); workers = @('default') },
        @{ id = 'm2w2'; mounts = @('default', 'tenant2'); workers = @('default', 'tenant2') },
        @{ id = 'm4w3'; mounts = @('default', 'tenant2', 'tenant3', 'tenant4'); workers = @('tenant2', 'tenant3', 'tenant4') }
    )
    $cells = @()
    $selectedPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $italyCodeunits = @(139709, 139711, 139723, 139728, 139729, 139809, 139811, 139823, 139828, 139851, 139865)
    foreach ($country in @('W1', 'DE', 'CA', 'US', 'IT')) {
        $routes = @($inventory.routes | Where-Object {
            $country -cin $_.countriesSelectingThisSourceVariant -and
            $country -cin $_.manifestIncludedInCountryPackageSettings -and
            $country -cnotin $_.unsupportedCountries -and
            ('All' -cin $_.supportedCountries -or $country -cin $_.supportedCountries) -and
            ($country -cin @('W1', 'DE') -or
                ($country -cin @('CA', 'US') -and $_.appName -ceq 'IRS Forms Tests') -or
                ($country -ceq 'IT' -and $_.codeunit -in $italyCodeunits))
        })
        if ($routes.Count -eq 0) { throw "Missing declared routes for $country." }
        $keys = @($routes | ForEach-Object { "$($_.appId)/$($_.codeunit)/$($_.buildMode)" })
        if (@($keys | Sort-Object -Unique).Count -ne $keys.Count) { throw "Ambiguous source variants for $country." }
        foreach ($route in $routes) {
            if (-not $laneSettings.ContainsKey($route.buildMode)) { throw 'Unrouted test lane.' }
            $null = $selectedPaths.Add($route.path)
        }
        $lanes = @(foreach ($lane in @('Default', 'IntegrationTests', 'UncategorizedTests', 'LegacyTestsBucket1', 'LegacyTestsBucket2')) {
            $members = @($routes | Where-Object buildMode -CEQ $lane)
            if ($members.Count) {
                @{
                    id = $lane; settings = $laneSettings[$lane]
                    template = 'lane-specific detached READ_ONLY default-test-template, frozen before discovery'
                    discovery = $(if ($lane -like 'Legacy*') { 'explicit-app-and-codeunit-without-testType-filter' } else { 'typed-all-inventory-codeunits-not-only-RequiredTestIsolation-Disabled' })
                    routes = $members
                    runtimeCaseCount = $null
                }
            }
        })
        foreach ($configuration in $configurations) {
            $cells += @{
                identity = "$country/$($configuration.id)/1"; country = $country; trial = 1
                comparison = $(if ($country -cin @('W1', 'DE')) { 'primary' } elseif ($country -ceq 'IT') { 'Italy-localized-fixes' } else { 'IRS-only-supplement' })
                configuration = $configuration; lanes = $lanes
                sharedPackageKey = $country
            }
        }
    }
    @{
        schemaVersion = 2; status = 'DRAFT_EXECUTABLE_OPT_IN'; executionReady = $true
        pins = $pins; cells = $cells
        primaryCells = 6; supplementaryIRSCells = 6; supplementaryItalyCells = 3
        maxParallel = 2; concurrencyGroup = 'sql-api-653393-expanded-api-diagnostic'
        sharedBuildCountries = @('W1', 'DE', 'CA', 'US', 'IT')
        italyCoverage = @{
            codeunits = $italyCodeunits
            reason = 'Table12170 Payment Lines and Operation Occurred Date only exist in IT; exercise a91e0d9308 and4902a412d0 rather than claiming W1/DE exercised these branches.'
            metadata = @('src/Layers/IT/BaseApp/Local/Foundation/PaymentTerms/PaymentLines.Table.al',
                'src/Layers/IT/BaseApp/Sales/Document/SalesHeader.Table.al',
                'src/Layers/IT/BaseApp/Purchases/Document/PurchaseHeader.Table.al')
        }
        sourceVariants = 167; plannedSourceVariants = $selectedPaths.Count
        uncoveredVariants = @($inventory.routes | Where-Object { -not $selectedPaths.Contains($_.path) })
        runtimeVerified = $false; allCountriesCovered = $false
        skips = 'Preserve reviewed pre-existing skips; remove only explicitly reviewed enablement entries. Never infer executed cases from declarations.'
        blockedBy = @()
    }
}

function Get-ExpandedApiCaseKey {
    param([Parameter(Mandatory)]$Case)
    foreach ($field in @('country', 'lane', 'appId', 'codeunitId', 'method')) {
        if ([string]::IsNullOrWhiteSpace([string]$Case.$field) -or [string]$Case.$field -match '[|\r\n]') {
            throw "Invalid runtime case identity field $field."
        }
    }
    "$($Case.country)|$($Case.lane)|$($Case.appId)|$($Case.codeunitId)|$($Case.method)"
}

function Assert-ExpandedApiCohort {
    param([Parameter(Mandatory)][array]$Discovered, [Parameter(Mandatory)][array]$Results)
    if (-not $Discovered.Count -or $Discovered.Count -ne $Results.Count) { throw 'Missing or truncated runtime cohort.' }
    $expected = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($case in $Discovered) {
        if ($case.skipped -isnot [bool]) { throw 'Discovery must record an explicit Boolean skip state.' }
        $key = Get-ExpandedApiCaseKey $case
        if ($expected.ContainsKey($key)) { throw 'Duplicate discovery case.' }
        $expected.Add($key, $case)
    }
    foreach ($case in $Results) {
        $key = Get-ExpandedApiCaseKey $case
        if (-not $expected.ContainsKey($key)) { throw 'Unexpected or duplicate result case.' }
        if ($case.status -cnotin @('Passed', 'Skipped', 'Failed', 'Error') -or
            ($case.status -ceq 'Skipped') -ne $expected[$key].skipped) {
            throw 'Unknown result state or changed skip state.'
        }
        if ($case.status -cin @('Failed', 'Error')) { throw 'Original test failures cannot qualify.' }
        $null = $expected.Remove($key)
    }
}

function Get-ExpandedCohortSignature {
    param([Parameter(Mandatory)][array]$Cases)
    $rows = @(foreach ($case in $Cases | Sort-Object country, lane, appId, codeunitId, method) {
        [ordered]@{
            key = Get-ExpandedApiCaseKey $case; skipped = $case.skipped
            appName = $case.appName; codeunitName = $case.codeunitName
            compiledIsolationSelector = $case.compiledIsolationSelector; runner = $case.runner
        }
    })
    ConvertTo-Json -InputObject $rows -Depth 8 -Compress
}

function Assert-ExpandedApiPackageManifest {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$Country,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$SourceHead,
        [Parameter(Mandatory)][string]$SourceTree,
        [Parameter(Mandatory)][string]$PackageDirectory
    )
    if ($Manifest.country -cne $Country -or $Manifest.runId -cne $RunId -or
        $Manifest.sourceHead -cne $SourceHead -or $Manifest.sourceTree -cne $SourceTree -or
        $Manifest.freshCompilation -isnot [bool] -or -not $Manifest.freshCompilation -or $Manifest.attempt -ne 1 -or
        $RunId -in @('37372848860', '37634358042', '37758493320') -or
        $SourceHead -notmatch '^[a-f0-9]{40}$' -or $SourceTree -notmatch '^[a-f0-9]{40}$') {
        throw 'Packages must come from the same new shared compilation, run, source and attempt.'
    }
    $pins = Get-ExpandedApiPinSet
    foreach ($key in @('platform', 'application', 'helper', 'alGo', 'image')) {
        if ($Manifest.pins.$key -cne $pins[$key]) { throw "Package $key pin drift." }
    }
    if (@($Manifest.artifacts).Count -ne 2 -or
        @($Manifest.artifacts.kind | Sort-Object -Unique).Count -ne 2 -or
        @($Manifest.artifacts.id | Sort-Object -Unique).Count -ne 2) {
        throw 'Exactly one Apps and one TestApps immutable artifact are required.'
    }
    foreach ($artifact in $Manifest.artifacts) {
        if ($artifact.kind -cnotin @('Apps', 'TestApps') -or [string]$artifact.id -notmatch '^[1-9]\d{0,19}$' -or
            $artifact.sha256 -notmatch '^[a-f0-9]{64}$' -or $artifact.expired -isnot [bool] -or $artifact.expired) {
            throw 'Invalid artifact identity, digest or expiry.'
        }
    }
    $files = @($Manifest.files)
    if ($files.Count -eq 0) { throw 'Empty package manifest.' }
    $actual = @(Get-ChildItem -LiteralPath $PackageDirectory -Recurse -File)
    if ($actual.Count -ne $files.Count) { throw 'Package directory must contain exactly the sealed files.' }
    $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $files) {
        if ($file.path -notmatch '^(Apps|TestApps)\\[^\\/:*?"<>|\r\n]+\.app$' -or
            -not $names.Add($file.path) -or $file.sha256 -notmatch '^[a-f0-9]{64}$' -or
            [long]$file.bytes -le 0) { throw 'Invalid or duplicate package file.' }
        $path = Join-Path $PackageDirectory $file.path
        $item = Get-Item -LiteralPath $path
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint -or
            $item.Length -ne [long]$file.bytes -or (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -cne $file.sha256) {
            throw 'Package bytes differ from the shared sealed manifest.'
        }
    }
    foreach ($kind in @('Apps', 'TestApps')) {
        if (-not @($files | Where-Object { $_.path.StartsWith("$kind\", [StringComparison]::Ordinal) }).Count) {
            throw "No $kind packages were sealed."
        }
    }
}

function Assert-ExpandedApiEvidence {
    param([Parameter(Mandatory)]$Evidence, [Parameter(Mandatory)]$Cell)
    $pins = Get-ExpandedApiPinSet
    if ($Evidence.identity -cne $Cell.identity -or $Evidence.attempt -ne 1 -or
        $Evidence.originalFailures -ne 0 -or $Evidence.retries -ne 0 -or
        $Evidence.warmups -ne 0 -or $Evidence.probes -ne 0 -or
        $Evidence.actualNstVersion -cne $pins.platform -or $Evidence.actualImage -cne $pins.image -or
        $Evidence.actualMemoryBytes -ne $pins.memoryBytes) { throw 'Runtime identity, originals or actual resource pins do not qualify.' }
    if (($Evidence.mounts -join '|') -cne ($Cell.configuration.mounts -join '|') -or
        ($Evidence.workers -join '|') -cne ($Cell.configuration.workers -join '|')) { throw 'Actual mount/worker topology differs.' }
    foreach ($flag in @('originalFailuresPersisted', 'artifactTransportVerified', 'packageManifestVerified',
        'ownedCleanupVerified', 'resourceEvidenceComplete', 'phaseEvidenceComplete', 'runnerInventoryComplete',
        'templateFrozenBeforeDiscovery', 'templateDetachedReadOnly', 'discoveryRestoredInFinally')) {
        if ($Evidence.$flag -isnot [bool] -or -not $Evidence.$flag) { throw "Missing fail-closed evidence: $flag." }
    }
    $expected = @($Cell.lanes.id | Sort-Object)
    if ((@($Evidence.lanes.id | Sort-Object) -join '|') -cne ($expected -join '|')) { throw 'Incomplete or duplicate lane evidence.' }
    foreach ($lane in $Evidence.lanes) {
        $planned = @($Cell.lanes | Where-Object id -CEQ $lane.id)[0]
        if ($lane.company -cne $planned.settings.company -or $lane.testType -cne $planned.settings.testType) {
            throw 'Lane company or effective test type changed.'
        }
        $required = @($planned.routes | ForEach-Object { "$($_.appId)/$($_.codeunit)" } | Sort-Object -Unique)
        $observed = @($lane.discovered | ForEach-Object { "$($_.appId)/$($_.codeunitId)" } | Sort-Object -Unique)
        if (($required -join '|') -cne ($observed -join '|')) { throw 'Runtime discovery omits or adds an inventory codeunit.' }
        foreach ($case in @($lane.discovered) + @($lane.results)) {
            if ($case.country -cne $Cell.country -or $case.lane -cne $lane.id) { throw 'Cross-lane or cross-country case evidence.' }
        }
        Assert-ExpandedApiCohort -Discovered $lane.discovered -Results $lane.results
    }
}

Export-ModuleMember -Function Get-ExpandedApiPinSet, Assert-ExpandedApiDispatch, Get-ExpandedApiPlan,
    Assert-ExpandedApiCohort, Assert-ExpandedApiPackageManifest, Assert-ExpandedApiEvidence, Get-ExpandedCohortSignature,
    Assert-ExpandedInstalledInventory
