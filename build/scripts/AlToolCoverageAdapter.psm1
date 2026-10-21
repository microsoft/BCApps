$script:SupportedCoverageTestTypes = @("IntegrationTest", "Uncategorized")

function Get-BcAppsCoverageContextValue {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $Context.Contains($Name)) {
        throw "AL-Go code coverage context is missing required field '$Name'."
    }

    return $Context[$Name]
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
        [System.Collections.IDictionary]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = "$(Get-BcAppsCoverageContextValue -Context $Context -Name $Name)"
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "AL-Go code coverage context field '$Name' must be a nonblank string."
    }
    return $value
}

function Assert-BcAppsCoverageContext {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        [hashtable]$CodeCoverageContext
    )

    $contractVersion = [int](Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "contractVersion")
    if ($contractVersion -ne 1) {
        throw "Unsupported AL-Go code coverage context version '$contractVersion'. Expected version 1."
    }
    if (-not [bool](Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "enabled")) {
        throw "AL-Go supplied a code coverage context with enabled=false."
    }

    $testType = Test-BcAppsCoverageString -Context $CodeCoverageContext -Name "testType"
    if ($testType -notin $script:SupportedCoverageTestTypes) {
        throw "BCApps supports the AL-Go coverage context only for IntegrationTest and Uncategorized, not '$testType'."
    }
    if ($Parameters.ContainsKey("testType") -and
        -not [string]::IsNullOrWhiteSpace("$($Parameters["testType"])") -and
        "$($Parameters["testType"])" -ne $testType) {
        throw "AL-Go test parameters specify testType '$($Parameters["testType"])', but the coverage context specifies '$testType'."
    }

    $app = ConvertTo-BcAppsCoverageHashtable `
        -InputObject (Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "app") `
        -Description "AL-Go code coverage context app"
    $appId = Test-BcAppsCoverageString -Context $app -Name "id"
    $appName = Test-BcAppsCoverageString -Context $app -Name "name"
    $null = Test-BcAppsCoverageString -Context $app -Name "path"
    $null = Get-BcAppsCoverageContextValue -Context $app -Name "disabledTests"

    if (-not "$($Parameters["extensionId"])".Equals(
            $appId,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw "AL-Go test parameters specify extensionId '$($Parameters["extensionId"])', but the coverage context app ID is '$appId'."
    }
    if (-not "$($Parameters["appName"])".Equals(
            $appName,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw "AL-Go test parameters specify appName '$($Parameters["appName"])', but the coverage context app name is '$appName'."
    }

    $result = ConvertTo-BcAppsCoverageHashtable `
        -InputObject (Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "result") `
        -Description "AL-Go code coverage context result"
    if (-not $result.ContainsKey("coverageIsComplete")) {
        throw "AL-Go code coverage context result is missing required field 'coverageIsComplete'."
    }

    $supported = [bool](Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "supported")
    if ($supported) {
        $mode = Test-BcAppsCoverageString -Context $CodeCoverageContext -Name "mode"
        if ($mode -ne "line") {
            throw "BCApps supports only line coverage mode, not '$mode'."
        }

        $formats = @(
            Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "formats"
        )
        if ($formats.Count -eq 0 -or "bc-json" -notin $formats) {
            throw "Supported AL-Go code coverage requires the authoritative 'bc-json' format."
        }

        $sourceRoots = @(
            Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "sourceRoots"
        )
        $sourceRootDetails = @(
            Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "sourceRootDetails"
        )
        if ($sourceRoots.Count -eq 0 -or $sourceRoots.Count -ne $sourceRootDetails.Count) {
            throw "Supported AL-Go code coverage requires aligned, non-empty sourceRoots and sourceRootDetails."
        }
        if (@($sourceRootDetails | Where-Object { "$($_.kind)" -eq "app" }).Count -eq 0) {
            throw "Supported AL-Go code coverage requires at least one regular app source root."
        }

        foreach ($pathField in @("coverageOutputPath", "outputDirectory", "alToolModulePath", "alToolPath")) {
            $null = Test-BcAppsCoverageString -Context $CodeCoverageContext -Name $pathField
        }
        if (-not (Test-Path -LiteralPath $CodeCoverageContext["alToolModulePath"] -PathType Leaf)) {
            throw "AL-Go AlTool runner module '$($CodeCoverageContext["alToolModulePath"])' does not exist."
        }
        if (-not (Test-Path -LiteralPath $CodeCoverageContext["alToolPath"] -PathType Leaf)) {
            throw "AL-Go pinned AlTool '$($CodeCoverageContext["alToolPath"])' does not exist."
        }
    }

    return @{
        App = $app
        Result = $result
        Supported = $supported
        TestType = $testType
    }
}

function Invoke-BcAppsCoverageAwareTestRun {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        [hashtable]$CodeCoverageContext,
        [Parameter(Mandatory = $true)]
        [string]$FallbackScriptPath
    )

    $validated = Assert-BcAppsCoverageContext `
        -Parameters $Parameters -CodeCoverageContext $CodeCoverageContext
    $app = $validated.App

    if (-not $validated.Supported) {
        $reason = "$(Get-BcAppsCoverageContextValue -Context $CodeCoverageContext -Name "reason")"
        Write-Host "::warning::AL-Go code coverage is unsupported for '$($app["name"])'. $reason Running the app once with BcContainerHelper."

        $fallbackParameters = $Parameters.Clone()
        $fallbackParameters["appName"] = "$($app["name"])"
        $fallbackParameters["extensionId"] = "$($app["id"])"
        $fallbackParameters["disabledTests"] = @($app["disabledTests"])
        $fallbackParameters["returnTrueIfAllPassed"] = $true
        return [bool](
            . $FallbackScriptPath -parameters $fallbackParameters `
                -TestType $validated.TestType `
                -UseSuppliedDisabledTests `
                -SkipAutomaticDisabledPass `
                -SkipTestTolerance
        )
    }

    $modulePath = "$($CodeCoverageContext["alToolModulePath"])"
    Import-Module $modulePath -Force
    $runner = Get-Command Invoke-AlToolTestRun -Module ([System.IO.Path]::GetFileNameWithoutExtension($modulePath)) `
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

    $disabledTests = @(
        @($app["disabledTests"]) |
            ForEach-Object {
                ConvertTo-BcAppsCoverageHashtable `
                    -InputObject $_ -Description "AL-Go disabled-test entry"
            }
    )
    $coverageIsComplete = $false
    $passed = [bool](& $runner `
        -ContainerName "$($Parameters["containerName"])" `
        -Credential $Parameters["credential"] `
        -ExtensionId "$($app["id"])" `
        -AppName "$($app["name"])" `
        -Tenant $tenant `
        -CompanyName "$($Parameters["companyName"])" `
        -JUnitResultFileName "$($Parameters["JUnitResultFileName"])" `
        -TestType $validated.TestType `
        -DisabledTests $disabledTests `
        -AlToolPath "$($CodeCoverageContext["alToolPath"])" `
        -CoverageMode "$($CodeCoverageContext["mode"])" `
        -CoverageFormats @($CodeCoverageContext["formats"]) `
        -CoverageSourceRoots @($CodeCoverageContext["sourceRoots"]) `
        -CoverageOutputPath "$($CodeCoverageContext["coverageOutputPath"])" `
        -CoverageIsComplete ([ref]$coverageIsComplete))

    $CodeCoverageContext["result"]["coverageIsComplete"] = [bool]$coverageIsComplete
    return $passed
}

Export-ModuleMember -Function Invoke-BcAppsCoverageAwareTestRun
