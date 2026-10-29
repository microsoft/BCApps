BeforeAll {
    function Get-AppJsonFromAppFile {
        param(
            [Parameter(Mandatory = $true)]
            [string]$appFile
        )

        return Get-Content -LiteralPath $appFile -Raw -Encoding UTF8 | ConvertFrom-Json
    }

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
        [string[]]$CoverageAppPaths,
        [string]$CoverageOutputPath,
        [ref]$CoverageIsComplete
    )

    [System.IO.Directory]::CreateDirectory($CoverageOutputPath) | Out-Null
    foreach ($format in $CoverageFormats) {
        if ($env:BCAPPS_ALTOOL_SKIP_FORMAT -eq $format) {
            continue
        }

        $fileName = if ($format -eq "bc-json") {
            "coverage.bc.json"
        }
        else {
            "coverage.cobertura.xml"
        }
        "coverage-$format" | Set-Content -LiteralPath (Join-Path $CoverageOutputPath $fileName)
    }
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
        appPaths = @($CoverageAppPaths)
        outputPath = $CoverageOutputPath
    } | ConvertTo-Json -Depth 20 |
        Set-Content -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE
    if ($env:BCAPPS_ALTOOL_NO_COMPLETENESS -ne "true") {
        $CoverageIsComplete.Value = $env:BCAPPS_ALTOOL_COMPLETE -ne "false"
    }
    return ($env:BCAPPS_ALTOOL_RESULT -ne "false")
}

Export-ModuleMember -Function Invoke-AlToolTestRun
'@ | Set-Content -LiteralPath $Path
    }

    function Get-TestParameterSet {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Root,
            [string]$TestType = "IntegrationTest"
        )

        $modulePath = Join-Path $Root "AlToolTestRunner.psm1"
        $alToolPath = Join-Path $Root "altool.exe"
        $sourceRoot = Join-Path $Root "app"
        $outputDirectory = Join-Path $Root "coverage"
        New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null
        New-Item -ItemType File -Path $alToolPath -Force | Out-Null
        Out-TestAlToolModule -Path $modulePath

        $securePassword = New-Object System.Security.SecureString
        return @{
            containerName = "bcapps"
            credential = [pscredential]::new("admin", $securePassword)
            extensionId = "11111111-1111-1111-1111-111111111111"
            appName = "Tests"
            tenant = "tenant2"
            companyName = "CRONUS"
            JUnitResultFileName = Join-Path $Root "results.xml"
            testType = $TestType
            disabledTests = @(
                @{
                    codeunitName = "Disabled Codeunit"
                    method = @("Disabled Method")
                }
            )
            codeCoverageMode = "line"
            codeCoverageFormats = @("bc-json", "cobertura")
            codeCoverageSourceRoots = @($sourceRoot)
            codeCoverageOutputPath = $outputDirectory
            codeCoverageAlToolModulePath = $modulePath
            codeCoverageAlToolPath = $alToolPath
            codeCoverageIsComplete = $null
        }
    }

    function Set-TestCoverageApps {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Root,
            [Parameter(Mandatory = $true)]
            [hashtable]$Parameters
        )

        $appOneId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $appTwoId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
        $unrelatedId = "cccccccc-cccc-cccc-cccc-cccccccccccc"
        $appOnePath = Join-Path $Root "AppOne.app"
        $appTwoPath = Join-Path $Root "AppTwo.app"
        $unrelatedPath = Join-Path $Root "Unrelated.app"
        @{ id = $appOneId } | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $appOnePath -Encoding UTF8
        @{ id = $appTwoId } | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $appTwoPath -Encoding UTF8
        @{ id = $unrelatedId } | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $unrelatedPath -Encoding UTF8

        $appsJsonPath = Join-Path $Root "DownloadedApps.json"
        @(
            "($appTwoPath)",
            $unrelatedPath,
            $appOnePath,
            $appTwoPath
        ) | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $appsJsonPath -Encoding UTF8
        $env:_devAlToolCoverageAppsJson = $appsJsonPath
        $Parameters.codeCoverageApplicationIds = @(
            $appTwoId.ToUpperInvariant(),
            $appOneId
        )

        return @{
            AppOneId = $appOneId
            AppOnePath = $appOnePath
            AppTwoId = $appTwoId
            AppTwoPath = $appTwoPath
            AppsJsonPath = $appsJsonPath
        }
    }
}

Describe "BCApps per-app AL-Go coverage adapter" {
    BeforeEach {
        Mock -ModuleName AlToolCoverageAdapter Get-AppJsonFromAppFile {
            param([string]$appFile)
            return Get-Content -LiteralPath $appFile -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        $env:BCAPPS_ALTOOL_CAPTURE = Join-Path $TestDrive "altool-capture.json"
        Remove-Item -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE -Force -ErrorAction SilentlyContinue
        $env:BCAPPS_ALTOOL_RESULT = "true"
        $env:BCAPPS_ALTOOL_COMPLETE = "true"
        Remove-Item Env:\BCAPPS_ALTOOL_SKIP_FORMAT -ErrorAction SilentlyContinue
        Remove-Item Env:\BCAPPS_ALTOOL_NO_COMPLETENESS -ErrorAction SilentlyContinue
        Remove-Item Env:\_devAlToolCoverageAppsJson -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Item Env:\BCAPPS_ALTOOL_CAPTURE -ErrorAction SilentlyContinue
        Remove-Item Env:\BCAPPS_ALTOOL_RESULT -ErrorAction SilentlyContinue
        Remove-Item Env:\BCAPPS_ALTOOL_COMPLETE -ErrorAction SilentlyContinue
        Remove-Item Env:\BCAPPS_ALTOOL_SKIP_FORMAT -ErrorAction SilentlyContinue
        Remove-Item Env:\BCAPPS_ALTOOL_NO_COMPLETENESS -ErrorAction SilentlyContinue
        Remove-Item Env:\_devAlToolCoverageAppsJson -ErrorAction SilentlyContinue
        Remove-Module AlToolTestRunner -Force -ErrorAction SilentlyContinue
    }

    It "runs the current app once through the action-owned AlTool runner" {
        $root = Join-Path $TestDrive "supported"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $coverageApps = Set-TestCoverageApps -Root $root -Parameters $parameters

        Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters |
            Should -BeTrue

        $parameters.codeCoverageIsComplete | Should -BeTrue
        $capture = Get-Content -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE -Raw | ConvertFrom-Json
        $capture.containerName | Should -Be "bcapps"
        $capture.appId | Should -Be $parameters.extensionId
        $capture.appName | Should -Be $parameters.appName
        $capture.tenant | Should -Be "tenant2"
        $capture.companyName | Should -Be "CRONUS"
        $capture.junitResultFileName | Should -Be $parameters.JUnitResultFileName
        $capture.testType | Should -Be "IntegrationTest"
        @($capture.disabledTests).Count | Should -Be 1
        $capture.disabledTests[0].codeunitName | Should -Be "Disabled Codeunit"
        $capture.alToolPath | Should -Be $parameters.codeCoverageAlToolPath
        $capture.mode | Should -Be "line"
        @($capture.formats) | Should -Be @("bc-json", "cobertura")
        @($capture.sourceRoots) | Should -Be @($parameters.codeCoverageSourceRoots)
        @($capture.appPaths) | Should -Be @(
            $coverageApps.AppOnePath,
            $coverageApps.AppTwoPath
        )
        $capture.outputPath | Should -Be $parameters.codeCoverageOutputPath
        Test-Path -LiteralPath $parameters.JUnitResultFileName -PathType Leaf |
            Should -BeTrue
        Test-Path -LiteralPath (
            Join-Path $parameters.codeCoverageOutputPath "coverage.bc.json"
        ) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (
            Join-Path $parameters.codeCoverageOutputPath "coverage.cobertura.xml"
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
        $parameters = Get-TestParameterSet -Root $root
        $env:BCAPPS_ALTOOL_RESULT = "false"

        Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters |
            Should -BeFalse

        $parameters.codeCoverageIsComplete | Should -BeTrue
        Test-Path -LiteralPath (
            Join-Path $parameters.codeCoverageOutputPath "coverage.bc.json"
        ) -PathType Leaf | Should -BeTrue
        (Get-Content -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE -Raw |
            ConvertFrom-Json).appPaths | Should -BeNullOrEmpty
    }

    It "propagates an incomplete coverage result independently of test success" {
        $root = Join-Path $TestDrive "incomplete-coverage"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $env:BCAPPS_ALTOOL_COMPLETE = "false"

        Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters |
            Should -BeTrue

        $parameters.codeCoverageIsComplete | Should -BeFalse
    }

    It "uses the default tenant when AL-Go does not supply one" {
        $root = Join-Path $TestDrive "default-tenant"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $parameters.Remove("tenant")

        Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters |
            Should -BeTrue

        (Get-Content -LiteralPath $env:BCAPPS_ALTOOL_CAPTURE -Raw |
            ConvertFrom-Json).tenant | Should -Be "default"
    }

    It "fails closed when the runner omits a requested artifact" {
        $root = Join-Path $TestDrive "missing-artifact"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $env:BCAPPS_ALTOOL_SKIP_FORMAT = "cobertura"

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*did not create the requested 'cobertura' artifact*"
        $parameters.codeCoverageIsComplete | Should -BeTrue
    }

    It "fails closed when the runner omits coverage completeness" {
        $root = Join-Path $TestDrive "missing-completeness"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $env:BCAPPS_ALTOOL_NO_COMPLETENESS = "true"

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*did not report code coverage completeness*"
        $parameters.codeCoverageIsComplete | Should -BeNullOrEmpty
    }

    It "fails closed when coverage is supplied for Legacy" {
        $root = Join-Path $TestDrive "legacy"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root -TestType "Legacy"

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*only for IntegrationTest and Uncategorized*"
    }

    It "fails closed when a required coverage parameter is missing" {
        $root = Join-Path $TestDrive "missing-field"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $parameters.Remove("codeCoverageAlToolPath")

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*missing required coverage field 'codeCoverageAlToolPath'*"
    }

    It "fails closed when a required dev coverage package is missing" {
        $root = Join-Path $TestDrive "missing-coverage-app"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $coverageApps = Set-TestCoverageApps -Root $root -Parameters $parameters
        $parameters.codeCoverageApplicationIds += "dddddddd-dddd-dddd-dddd-dddddddddddd"

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*package for application ID 'dddddddd-dddd-dddd-dddd-dddddddddddd' was not found*"
        Test-Path -LiteralPath $coverageApps.AppOnePath -PathType Leaf | Should -BeTrue
    }

    It "fails closed when the dev package list is present without application IDs" {
        $root = Join-Path $TestDrive "missing-coverage-app-ids"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $null = Set-TestCoverageApps -Root $root -Parameters $parameters
        $parameters.Remove("codeCoverageApplicationIds")

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*missing required coverage field 'codeCoverageApplicationIds'*"
    }

    It "fails closed when distinct dev coverage packages have the same app ID" {
        $root = Join-Path $TestDrive "duplicate-coverage-app"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $coverageApps = Set-TestCoverageApps -Root $root -Parameters $parameters
        $duplicatePath = Join-Path $root "Duplicate.app"
        @{ id = $coverageApps.AppOneId } | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $duplicatePath -Encoding UTF8
        @(
            $coverageApps.AppOnePath,
            $duplicatePath,
            $coverageApps.AppTwoPath
        ) | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $coverageApps.AppsJsonPath -Encoding UTF8

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*duplicate packages for application ID '$($coverageApps.AppOneId)'*"
    }

    It "fails closed when a dev coverage package path is not an existing app file" {
        $root = Join-Path $TestDrive "invalid-coverage-app"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $parameters.codeCoverageApplicationIds = @(
            "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        )
        $appsJsonPath = Join-Path $root "DownloadedApps.json"
        @((Join-Path $root "Missing.app")) | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $appsJsonPath -Encoding UTF8
        $env:_devAlToolCoverageAppsJson = $appsJsonPath

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*must be an existing .app file*"
    }

    It "fails closed when a source root is not absolute" {
        $root = Join-Path $TestDrive "relative-root"
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $parameters = Get-TestParameterSet -Root $root
        $parameters.codeCoverageSourceRoots = @("src/App")

        {
            Invoke-BcAppsCoverageAwareTestRun -Parameters $parameters
        } | Should -Throw "*must be an absolute path*"
    }
}
