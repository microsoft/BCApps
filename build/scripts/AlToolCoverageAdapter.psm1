$script:SupportedCoverageTestTypes = @("IntegrationTest", "Uncategorized")
$script:CoverageArtifacts = @{
    "bc-json" = "coverage.bc.json"
    "cobertura" = "coverage.cobertura.xml"
}

function Get-BcAppsCoverageParameterValue {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $Parameters.ContainsKey($Name)) {
        throw "AL-Go test parameters are missing required coverage field '$Name'."
    }

    return $Parameters[$Name]
}

function ConvertTo-BcAppsCoverageHashtable {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($InputObject -is [hashtable]) {
        return $InputObject
    }
    if ($InputObject -isnot [System.Collections.IDictionary]) {
        throw "$Description must be a hashtable."
    }

    $result = @{}
    foreach ($key in $InputObject.Keys) {
        $result["$key"] = $InputObject[$key]
    }
    return $result
}

function Test-BcAppsCoverageString {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = "$(Get-BcAppsCoverageParameterValue -Parameters $Parameters -Name $Name)"
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "AL-Go test parameter '$Name' must be a nonblank string."
    }
    return $value
}

function Get-BcAppsDevCoverageAppPaths {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    $appsJsonPath = "$env:_devAlToolCoverageAppsJson"
    if ([string]::IsNullOrWhiteSpace($appsJsonPath)) {
        return @()
    }

    if (-not (Test-Path -LiteralPath $appsJsonPath -PathType Leaf)) {
        throw "Temporary dev AlTool coverage app list '$appsJsonPath' does not exist."
    }

    $applicationIds = @(
        Get-BcAppsCoverageParameterValue -Parameters $Parameters -Name "codeCoverageApplicationIds"
    )
    if ($applicationIds.Count -eq 0) {
        throw "Temporary dev AlTool coverage requires at least one regular source-root application ID."
    }

    $requiredApplicationIds = @{}
    foreach ($applicationId in $applicationIds) {
        $normalizedApplicationId = "$applicationId".Trim().ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($normalizedApplicationId)) {
            throw "Temporary dev AlTool coverage received a blank regular source-root application ID."
        }
        $requiredApplicationIds[$normalizedApplicationId] = $true
    }

    try {
        $downloadedApps = Get-Content -LiteralPath $appsJsonPath -Raw -Encoding UTF8 -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to read temporary dev AlTool coverage app list '$appsJsonPath'. Error: $($_.Exception.Message)"
    }

    $candidatePaths = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $selectedPackages = @{}
    foreach ($downloadedApp in $downloadedApps) {
        $downloadedAppPath = "$downloadedApp".Trim()
        if ($downloadedAppPath.StartsWith("(") -and $downloadedAppPath.EndsWith(")")) {
            $downloadedAppPath = $downloadedAppPath.Substring(1, $downloadedAppPath.Length - 2)
        }
        if ([string]::IsNullOrWhiteSpace($downloadedAppPath)) {
            throw "Temporary dev AlTool coverage app list '$appsJsonPath' contains a blank path."
        }
        if (-not [System.IO.Path]::IsPathRooted($downloadedAppPath)) {
            throw "Temporary dev AlTool coverage app path '$downloadedAppPath' must be absolute."
        }

        $fullDownloadedAppPath = [System.IO.Path]::GetFullPath($downloadedAppPath)
        if (-not $candidatePaths.Add($fullDownloadedAppPath)) {
            continue
        }
        if (-not $fullDownloadedAppPath.EndsWith(".app", [System.StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $fullDownloadedAppPath -PathType Leaf)) {
            throw "Temporary dev AlTool coverage app path '$fullDownloadedAppPath' must be an existing .app file."
        }

        try {
            $appJson = Get-AppJsonFromAppFile -appFile $fullDownloadedAppPath
            $packageApplicationId = "$($appJson.id)".Trim().ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($packageApplicationId)) {
                throw "The package manifest does not contain an app ID."
            }
        }
        catch {
            throw "Failed to read temporary dev AlTool coverage package '$fullDownloadedAppPath'. Error: $($_.Exception.Message)"
        }

        if (-not $requiredApplicationIds.ContainsKey($packageApplicationId)) {
            continue
        }
        if ($selectedPackages.ContainsKey($packageApplicationId)) {
            throw "Temporary dev AlTool coverage found duplicate packages for application ID '$packageApplicationId': '$($selectedPackages[$packageApplicationId])' and '$fullDownloadedAppPath'."
        }
        $selectedPackages[$packageApplicationId] = $fullDownloadedAppPath
    }

    $sortedApplicationIds = [string[]]@($requiredApplicationIds.Keys)
    [System.Array]::Sort($sortedApplicationIds, [System.StringComparer]::Ordinal)
    $coverageAppPaths = @()
    foreach ($applicationId in $sortedApplicationIds) {
        if (-not $selectedPackages.ContainsKey($applicationId)) {
            throw "Temporary dev AlTool coverage package for application ID '$applicationId' was not found in '$appsJsonPath'."
        }
        $coverageAppPaths += "$($selectedPackages[$applicationId])"
    }
    return @($coverageAppPaths)
}

function Assert-BcAppsCoverageParameters {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    $testType = Test-BcAppsCoverageString -Parameters $Parameters -Name "testType"
    if ($testType -notin $script:SupportedCoverageTestTypes) {
        throw "BCApps supports AL-Go code coverage only for IntegrationTest and Uncategorized, not '$testType'."
    }

    foreach ($name in @(
        "containerName",
        "extensionId",
        "appName",
        "JUnitResultFileName",
        "codeCoverageOutputPath",
        "codeCoverageAlToolModulePath",
        "codeCoverageAlToolPath"
    )) {
        $null = Test-BcAppsCoverageString -Parameters $Parameters -Name $name
    }
    $null = Get-BcAppsCoverageParameterValue -Parameters $Parameters -Name "credential"
    $null = Get-BcAppsCoverageParameterValue -Parameters $Parameters -Name "disabledTests"
    $null = Get-BcAppsCoverageParameterValue -Parameters $Parameters -Name "codeCoverageIsComplete"

    $mode = Test-BcAppsCoverageString -Parameters $Parameters -Name "codeCoverageMode"
    if ($mode -ne "line") {
        throw "BCApps supports only line coverage mode, not '$mode'."
    }

    $formats = @(
        Get-BcAppsCoverageParameterValue -Parameters $Parameters -Name "codeCoverageFormats"
    )
    if ($formats.Count -eq 0 -or "bc-json" -notin $formats) {
        throw "Supported AL-Go code coverage requires the authoritative 'bc-json' format."
    }
    foreach ($format in $formats) {
        if (-not $script:CoverageArtifacts.ContainsKey("$format")) {
            throw "Unsupported AL-Go code coverage format '$format'."
        }
    }

    $sourceRoots = @(
        Get-BcAppsCoverageParameterValue -Parameters $Parameters -Name "codeCoverageSourceRoots"
    )
    if ($sourceRoots.Count -eq 0) {
        throw "Supported AL-Go code coverage requires at least one source root."
    }
    foreach ($sourceRoot in $sourceRoots) {
        if ([string]::IsNullOrWhiteSpace("$sourceRoot") -or
            -not [System.IO.Path]::IsPathRooted("$sourceRoot")) {
            throw "AL-Go code coverage source root '$sourceRoot' must be an absolute path."
        }
        if (-not (Test-Path -LiteralPath "$sourceRoot" -PathType Container)) {
            throw "AL-Go code coverage source root '$sourceRoot' does not exist."
        }
    }

    foreach ($pathField in @("codeCoverageAlToolModulePath", "codeCoverageAlToolPath")) {
        if (-not (Test-Path -LiteralPath $Parameters[$pathField] -PathType Leaf)) {
            throw "AL-Go coverage path '$($Parameters[$pathField])' from '$pathField' does not exist."
        }
    }

    $disabledTests = @(
        @($Parameters["disabledTests"]) |
            ForEach-Object {
                ConvertTo-BcAppsCoverageHashtable `
                    -InputObject $_ -Description "AL-Go disabled-test entry"
            }
    )

    return @{
        DisabledTests = $disabledTests
        Formats = $formats
        SourceRoots = $sourceRoots
        TestType = $testType
    }
}

function Assert-BcAppsCoverageResult {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        [string[]]$Formats
    )

    if ($null -eq $Parameters["codeCoverageIsComplete"]) {
        throw "The action-owned AlTool runner did not report code coverage completeness."
    }

    foreach ($format in $Formats) {
        $artifactPath = Join-Path `
            "$($Parameters["codeCoverageOutputPath"])" `
            $script:CoverageArtifacts[$format]
        if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
            throw "The action-owned AlTool runner did not create the requested '$format' artifact '$artifactPath'."
        }
    }
}

<#
.SYNOPSIS
    Runs one coverage-enabled BCApps test app through the action-owned AlTool runner.
.DESCRIPTION
    Validates the temporary AL-Go coverage parameters, invokes Invoke-AlToolTestRun,
    propagates coverage completeness, and verifies the requested fixed artifacts.
#>
function Invoke-BcAppsCoverageAwareTestRun {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    $validated = Assert-BcAppsCoverageParameters -Parameters $Parameters
    $modulePath = "$($Parameters["codeCoverageAlToolModulePath"])"
    Import-Module $modulePath -Force
    $runner = Get-Command Invoke-AlToolTestRun `
        -Module ([System.IO.Path]::GetFileNameWithoutExtension($modulePath)) `
        -ErrorAction Stop
    $coverageAppPaths = @(Get-BcAppsDevCoverageAppPaths -Parameters $Parameters)
    if ($coverageAppPaths.Count -gt 0 -and
        -not $runner.Parameters.ContainsKey("CoverageAppPaths")) {
        throw "The action-owned AlTool runner does not support temporary dev coverage app packages."
    }

    $tenant = if (
        $Parameters.ContainsKey("tenant") -and
        -not [string]::IsNullOrWhiteSpace("$($Parameters["tenant"])")
    ) {
        "$($Parameters["tenant"])"
    }
    else {
        "default"
    }

    $coverageIsComplete = $null
    $runnerParameters = @{
        ContainerName = "$($Parameters["containerName"])"
        Credential = $Parameters["credential"]
        ExtensionId = "$($Parameters["extensionId"])"
        AppName = "$($Parameters["appName"])"
        Tenant = $tenant
        CompanyName = "$($Parameters["companyName"])"
        JUnitResultFileName = "$($Parameters["JUnitResultFileName"])"
        TestType = $validated.TestType
        DisabledTests = $validated.DisabledTests
        AlToolPath = "$($Parameters["codeCoverageAlToolPath"])"
        CoverageMode = "$($Parameters["codeCoverageMode"])"
        CoverageFormats = $validated.Formats
        CoverageSourceRoots = $validated.SourceRoots
        CoverageOutputPath = "$($Parameters["codeCoverageOutputPath"])"
        CoverageIsComplete = [ref]$coverageIsComplete
    }
    if ($coverageAppPaths.Count -gt 0) {
        $runnerParameters.CoverageAppPaths = @($coverageAppPaths)
    }
    $passed = [bool](& $runner @runnerParameters)

    $Parameters["codeCoverageIsComplete"] = $coverageIsComplete
    Assert-BcAppsCoverageResult -Parameters $Parameters -Formats $validated.Formats
    return $passed
}

Export-ModuleMember -Function Invoke-BcAppsCoverageAwareTestRun
