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
    $passed = [bool](& $runner `
        -ContainerName "$($Parameters["containerName"])" `
        -Credential $Parameters["credential"] `
        -ExtensionId "$($Parameters["extensionId"])" `
        -AppName "$($Parameters["appName"])" `
        -Tenant $tenant `
        -CompanyName "$($Parameters["companyName"])" `
        -JUnitResultFileName "$($Parameters["JUnitResultFileName"])" `
        -TestType $validated.TestType `
        -DisabledTests $validated.DisabledTests `
        -AlToolPath "$($Parameters["codeCoverageAlToolPath"])" `
        -CoverageMode "$($Parameters["codeCoverageMode"])" `
        -CoverageFormats $validated.Formats `
        -CoverageSourceRoots $validated.SourceRoots `
        -CoverageOutputPath "$($Parameters["codeCoverageOutputPath"])" `
        -CoverageIsComplete ([ref]$coverageIsComplete))

    $Parameters["codeCoverageIsComplete"] = $coverageIsComplete
    Assert-BcAppsCoverageResult -Parameters $Parameters -Formats $validated.Formats
    return $passed
}

Export-ModuleMember -Function Invoke-BcAppsCoverageAwareTestRun
