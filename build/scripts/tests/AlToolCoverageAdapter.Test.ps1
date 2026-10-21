BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../AlToolCoverageAdapter.psm1"
    Import-Module $modulePath -Force

    function Out-TestAlToolModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    @'
function Invoke-AlToolTestRun {
    param(
        [string]$ContainerName,
        [pscredential]$Credential,
        [string]$ExtensionId,
        [string]$AppName,
        [string]$Tenant,
        [string]$CompanyName,
        [string]$JUnitResultFileName,
        [string]$TestType,
        [hashtable[]]$DisabledTests,
        [string]$AlToolPath,
        [string]$CoverageMode,
        [string[]]$CoverageFormats,
        [string[]]$CoverageSourceRoots,
        [string]$CoverageOutputPath,
        [ref]$CoverageIsComplete
    )

    [System.IO.Directory]::CreateDirectory($CoverageOutputPath) | Out-Null
    '{"schemaVersion":1,"mode":"line","files":[]}' |
        Set-Content -LiteralPath (Join-Path $CoverageOutputPath "coverage.bc.json")
    '<testsuites />' | Set-Content -LiteralPath $JUnitResultFileName
    @{
        containerName = $ContainerName
        appId = $ExtensionId
        appName = $AppName
        tenant = $Tenant
        companyName = $CompanyName
        junitResultFileName = $JUnitResultFileName
        testType = $TestType
        disabledTests = @($DisabledTests)
        alToolPath = $AlToolPath
        mode = $CoverageMode
        formats = @($CoverageFormats)
        sourceRoots = @($CoverageSourceRoots)
        outputPath = $CoverageOutputPath
    } | ConvertTo-Json -Depth 20 |
        Set-Content -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE
    $CoverageIsComplete.Value = $env:BCAPPS_ALTOOL_COMPLETE -ne "false"
    return ($env:BCAPPS_ALTOOL_RESULT -ne "false")
}

Export-ModuleMember -Function Invoke-AlToolTestRun
'@ | Set-Content -LiteralPath $Path
    }

    function Get-TestCoverageContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [bool]$Supported = $true,
        [string]$TestType = "IntegrationTest"
    )

    $modulePath = Join-Path $Root "AlToolTestRunner.psm1"
    $alToolPath = Join-Path $Root "altool.exe"
    $sourceRoot = Join-Path $Root "app"
    $outputDirectory = Join-Path $Root "coverage"
    New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null
    New-Item -ItemType File -Path $alToolPath -Force | Out-Null
    Out-TestAlToolModule -Path $modulePath

    return @{
        contractVersion = 1
        enabled = $true
        supported = $Supported
        reason = if ($Supported) { "" } else { "Platform version is below the minimum." }
        project = "build/projects/Test Apps W1"
        projectName = "Test Apps W1"
        buildMode = "Clean"
        testType = $TestType
        app = @{
            path = "src/Tests"
            id = "11111111-1111-1111-1111-111111111111"
            name = "Tests"
            disabledTests = @(
                @{
                    codeunitName = "Disabled Codeunit"
                    method = @("Disabled Method")
                }
            )
        }
        mode = "line"
        formats = @("bc-json", "cobertura")
        sourceRoots = @($sourceRoot)
        sourceRootDetails = @(
            @{
                path = "src/App"
                kind = "app"
                appId = "22222222-2222-2222-2222-222222222222"
                appName = "Application"
            }
        )
        coverageOutputPath = $outputDirectory
        outputDirectory = "CodeCoverage/Tests"
        alToolModulePath = $modulePath
        alToolPath = $alToolPath
        result = @{
            coverageIsComplete = $null
        }
    }
    }

    function Get-TestParameterSet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $securePassword = New-Object System.Security.SecureString
    return @{
        containerName = "bcapps"
        credential = [pscredential]::new("admin", $securePassword)
        extensionId = "11111111-1111-1111-1111-111111111111"
        appName = "Tests"
        tenant = "tenant2"
        companyName = "CRONUS"
        JUnitResultFileName = Join-Path $Root "results.xml"
        testType = "IntegrationTest"
    }
    }
}

Describe "BCApps per-app AL-Go coverage adapter" {
    BeforeEach {
        $env:BCAPPS_ALTOOL_CAPTURE = Join-Path $TestDrive "altool-capture.json"
        Remove-Item -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE -Force -ErrorAction SilentlyContinue
        $env:BCAPPS_ALTOOL_RESULT = "true"
        $env:BCAPPS_ALTOOL_COMPLETE = "true"
    }

    AfterEach {
        Remove-Item Env:\BCAPPS_ALTOOL_CAPTURE -ErrorAction SilentlyContinue
        Remove-Item Env:\BCAPPS_ALTOOL_RESULT -ErrorAction SilentlyContinue
        Remove-Item Env:\BCAPPS_ALTOOL_COMPLETE -ErrorAction SilentlyContinue
        Remove-Module AlToolTestRunner -Force -ErrorAction SilentlyContinue
    }

    It "runs the supplied app once through the action-owned AlTool runner" {
        $root = Join-Path $TestDrive "supported"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $context = Get-TestCoverageContext -Root $root
        $parameters = Get-TestParameterSet -Root $root
        $fallback = Join-Path $root "fallback.ps1"
        'throw "The BCH fallback must not run."' | Set-Content -LiteralPath $fallback

        Invoke-BcAppsCoverageAwareTestRun `
            -Parameters $parameters `
            -CodeCoverageContext $context `
            -FallbackScriptPath $fallback |
            Should -BeTrue

        $context.result.coverageIsComplete | Should -BeTrue
        $capture = Get-Content -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE -Raw | ConvertFrom-Json
        $capture.containerName | Should -Be "bcapps"
        $capture.appId | Should -Be $context.app.id
        $capture.appName | Should -Be $context.app.name
        $capture.tenant | Should -Be "tenant2"
        $capture.companyName | Should -Be "CRONUS"
        $capture.junitResultFileName | Should -Be $parameters.JUnitResultFileName
        $capture.testType | Should -Be "IntegrationTest"
        @($capture.disabledTests).Count | Should -Be 1
        $capture.disabledTests[0].codeunitName | Should -Be "Disabled Codeunit"
        $capture.alToolPath | Should -Be $context.alToolPath
        $capture.mode | Should -Be "line"
        @($capture.formats) | Should -Be @("bc-json", "cobertura")
        @($capture.sourceRoots) | Should -Be @($context.sourceRoots)
        $capture.outputPath | Should -Be $context.coverageOutputPath
        Test-Path -LiteralPath (
            Join-Path $context.coverageOutputPath "coverage.bc.json"
        ) -PathType Leaf | Should -BeTrue
        @(
            Get-ChildItem -LiteralPath $root -Filter "coverage-status.json" -File -Recurse
        ).Count | Should -Be 0
        (Get-Content -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE -Raw) |
            Should -Not -Match "credential|password|username"
    }

    It "preserves valid coverage completeness when tests fail" {
        $root = Join-Path $TestDrive "failed-tests"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $context = Get-TestCoverageContext -Root $root
        $parameters = Get-TestParameterSet -Root $root
        $fallback = Join-Path $root "fallback.ps1"
        'throw "The BCH fallback must not run."' | Set-Content -LiteralPath $fallback
        $env:BCAPPS_ALTOOL_RESULT = "false"

        Invoke-BcAppsCoverageAwareTestRun `
            -Parameters $parameters `
            -CodeCoverageContext $context `
            -FallbackScriptPath $fallback |
            Should -BeFalse

        $context.result.coverageIsComplete | Should -BeTrue
        Test-Path -LiteralPath (
            Join-Path $context.coverageOutputPath "coverage.bc.json"
        ) -PathType Leaf | Should -BeTrue
    }

    It "runs one BCH fallback without retry, tolerance, or disabled-test replacement when unsupported" {
        $root = Join-Path $TestDrive "unsupported"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $context = Get-TestCoverageContext -Root $root -Supported $false
        $parameters = Get-TestParameterSet -Root $root
        $fallback = Join-Path $root "fallback.ps1"
        $capturePath = Join-Path $root "fallback-capture.json"
        $env:BCAPPS_FALLBACK_CAPTURE = $capturePath
        @'
param(
    [hashtable]$parameters,
    [string]$TestType,
    [switch]$UseSuppliedDisabledTests,
    [switch]$SkipAutomaticDisabledPass,
    [switch]$SkipTestTolerance
)
@{
    appName = $parameters.appName
    extensionId = $parameters.extensionId
    disabledTests = @($parameters.disabledTests)
    returnTrueIfAllPassed = $parameters.returnTrueIfAllPassed
    testType = $TestType
    useSuppliedDisabledTests = $UseSuppliedDisabledTests.IsPresent
    skipAutomaticDisabledPass = $SkipAutomaticDisabledPass.IsPresent
    skipTestTolerance = $SkipTestTolerance.IsPresent
} | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $env:BCAPPS_FALLBACK_CAPTURE
return $true
'@ | Set-Content -LiteralPath $fallback

        try {
            Invoke-BcAppsCoverageAwareTestRun `
                -Parameters $parameters `
                -CodeCoverageContext $context `
                -FallbackScriptPath $fallback |
                Should -BeTrue

            $capture = Get-Content -LiteralPath $capturePath -Raw | ConvertFrom-Json
            $capture.appName | Should -Be $context.app.name
            $capture.extensionId | Should -Be $context.app.id
            @($capture.disabledTests).Count | Should -Be 1
            $capture.returnTrueIfAllPassed | Should -BeTrue
            $capture.testType | Should -Be "IntegrationTest"
            $capture.useSuppliedDisabledTests | Should -BeTrue
            $capture.skipAutomaticDisabledPass | Should -BeTrue
            $capture.skipTestTolerance | Should -BeTrue
            $context.result.coverageIsComplete | Should -BeNullOrEmpty
            Test-Path -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE | Should -BeFalse
        }
        finally {
            Remove-Item Env:\BCAPPS_FALLBACK_CAPTURE -ErrorAction SilentlyContinue
        }
    }

    It "fails closed for an invalid contract version" {
        $root = Join-Path $TestDrive "bad-version"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $context = Get-TestCoverageContext -Root $root
        $context.contractVersion = 2
        $parameters = Get-TestParameterSet -Root $root

        {
            Invoke-BcAppsCoverageAwareTestRun `
                -Parameters $parameters `
                -CodeCoverageContext $context `
                -FallbackScriptPath (Join-Path $root "fallback.ps1")
        } | Should -Throw "*Expected version 1*"
    }

    It "fails closed when coverage is supplied for Legacy" {
        $root = Join-Path $TestDrive "legacy"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $context = Get-TestCoverageContext -Root $root -TestType "Legacy"
        $parameters = Get-TestParameterSet -Root $root
        $parameters.testType = "Legacy"

        {
            Invoke-BcAppsCoverageAwareTestRun `
                -Parameters $parameters `
                -CodeCoverageContext $context `
                -FallbackScriptPath (Join-Path $root "fallback.ps1")
        } | Should -Throw "*only for IntegrationTest and Uncategorized*"
    }

    It "fails closed when the context app does not match the current AL-Go app" {
        $root = Join-Path $TestDrive "mismatch"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $context = Get-TestCoverageContext -Root $root
        $parameters = Get-TestParameterSet -Root $root
        $parameters.extensionId = "33333333-3333-3333-3333-333333333333"

        {
            Invoke-BcAppsCoverageAwareTestRun `
                -Parameters $parameters `
                -CodeCoverageContext $context `
                -FallbackScriptPath (Join-Path $root "fallback.ps1")
        } | Should -Throw "*coverage context app ID*"
    }

    It "fails closed when authoritative roots are missing regular app metadata" {
        $root = Join-Path $TestDrive "no-app-root"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $context = Get-TestCoverageContext -Root $root
        $context.sourceRootDetails[0].kind = "test"
        $parameters = Get-TestParameterSet -Root $root

        {
            Invoke-BcAppsCoverageAwareTestRun `
                -Parameters $parameters `
                -CodeCoverageContext $context `
                -FallbackScriptPath (Join-Path $root "fallback.ps1")
        } | Should -Throw "*regular app source root*"
    }
}
