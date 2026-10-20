$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../AlToolCoverageAdapter.psm1') -Force

    function New-TestCoverageContext {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Root
        )

        $coverageRoot = Join-Path (Join-Path $Root ".buildartifacts") "CodeCoverage"
        return @{
            Enabled = $true
            Project = "build/projects/Test Apps W1"
            ProjectName = "Unit Tests"
            BuildMode = "IntegrationTests"
            Mode = "line"
            Formats = @("bc-json")
            RepositoryRoot = $Root
            ProjectPath = $Root
            CoverageRoot = $coverageRoot
            StatusPath = Join-Path $coverageRoot "coverage-status.json"
            SidecarRoot = Join-Path $coverageRoot ".bcapps-runs"
            RunnerModulePath = ""
            SourceRoots = @(Join-Path $Root "src\App")
            SourceRootDetails = @(
                @{
                    path = "src/App"
                    kind = "app"
                    appId = "regular-app"
                    appName = "Regular App"
                }
            )
            ExpectedShards = @()
        }
    }

    function Write-TestCoverageSidecar {
        param(
            [Parameter(Mandatory = $true)]
            [hashtable]$Context,
            [Parameter(Mandatory = $true)]
            [string]$LogicalShard,
            [Parameter(Mandatory = $true)]
            [int]$Attempt,
            [Parameter(Mandatory = $true)]
            [string]$State,
            [bool]$Tracked = $true
        )

        $output = Get-BcAppsAlToolCoverageOutput -Context $Context -AppId "test-app" `
            -LogicalShard $LogicalShard -Attempt $Attempt
        New-Item -Path $Context.SidecarRoot -ItemType Directory -Force | Out-Null
        @{
            key = "test-app::$LogicalShard"
            appId = "test-app"
            appName = "Test App"
            logicalShard = $LogicalShard
            attempt = $Attempt
            outputDirectory = $output.RelativePath
            state = $State
            testsPassed = $State -ne "failed"
            tracked = $Tracked
            error = ""
        } | ConvertTo-Json -Depth 10 |
            Set-Content -LiteralPath (Join-Path $Context.SidecarRoot "$LogicalShard-$Attempt-$([guid]::NewGuid().ToString('N')).json") -Encoding UTF8
        return $output
    }
}

Describe "AlTool coverage shard selection" {
    It "derives normal and clean exclusion complements without double-running codeunits" {
        $catalog = @{
            "Test App" = @(
                [pscustomobject]@{ Id = 100; Name = "Normal One"; Tests = @("A", "B") }
                [pscustomobject]@{ Id = 200; Name = "Clean One"; Tests = @("C") }
                [pscustomobject]@{ Id = 300; Name = "Clean Two"; Tests = @("D", "E") }
            )
        }
        $required = @(
            [pscustomobject]@{
                Key = "Test App::200"
                AppName = "Test App"
                AppId = "test-app"
                CodeunitId = "200"
                CodeunitName = "Clean One"
                TestCount = 1
            }
            [pscustomobject]@{
                Key = "Test App::300"
                AppName = "Test App"
                AppId = "test-app"
                CodeunitId = "300"
                CodeunitName = "Clean Two"
                TestCount = 2
            }
        )

        $plan = New-BcAppsAlToolShardPlan -CodeunitsByApp $catalog `
            -RequiredDisabledWorkItems $required

        $plan.NormalTestCountByApp["Test App"] | Should -Be 2
        @($plan.NormalDisabledByApp["Test App"] | ForEach-Object { $_.codeunitName }) |
            Should -Be @("Clean One", "Clean Two")
        $plan.CleanWorkItems.Count | Should -Be 2

        $cleanOne = @($plan.CleanWorkItems | Where-Object { $_.CodeunitId -eq "200" })[0]
        @($cleanOne.CoverageDisabledTests | ForEach-Object { $_.codeunitName }) |
            Should -Be @("Normal One", "Clean Two")
        $cleanTwo = @($plan.CleanWorkItems | Where-Object { $_.CodeunitId -eq "300" })[0]
        @($cleanTwo.CoverageDisabledTests | ForEach-Object { $_.codeunitName }) |
            Should -Be @("Normal One", "Clean One")
    }

    It "fails when a required clean codeunit is absent from the AlTool catalog" {
        {
            New-BcAppsAlToolShardPlan -CodeunitsByApp @{
                "Test App" = @([pscustomobject]@{ Id = 100; Name = "Normal"; Tests = @("A") })
            } -RequiredDisabledWorkItems @([pscustomobject]@{
                    Key = "Test App::200"
                    AppName = "Test App"
                    AppId = "test-app"
                    CodeunitId = "200"
                    CodeunitName = "Missing"
                    TestCount = 1
                })
        } | Should -Throw "*Could not resolve clean codeunit*"
    }
}

Describe "AlTool coverage attempt paths" {
    BeforeEach {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("coverage-paths-" + [guid]::NewGuid().ToString("N"))
        New-Item -Path $script:tempRoot -ItemType Directory -Force | Out-Null
        $script:context = New-TestCoverageContext -Root $script:tempRoot
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "allocates unique output directories for every shard attempt" {
        $first = Get-BcAppsAlToolCoverageOutput -Context $script:context `
            -AppId "test app" -LogicalShard "normal" -Attempt 1
        $retry = Get-BcAppsAlToolCoverageOutput -Context $script:context `
            -AppId "test app" -LogicalShard "normal" -Attempt 2
        $clean = Get-BcAppsAlToolCoverageOutput -Context $script:context `
            -AppId "test app" -LogicalShard "clean-50000" -Attempt 1

        $first.FullPath | Should -Not -Be $retry.FullPath
        $first.FullPath | Should -Not -Be $clean.FullPath
        $retry.RelativePath | Should -Be "CodeCoverage/test-app/normal/2"
        $clean.RelativePath | Should -Be "CodeCoverage/test-app/clean-50000/1"
    }
}

Describe "AlTool coverage worker execution" {
    BeforeEach {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("coverage-worker-" + [guid]::NewGuid().ToString("N"))
        $actionPath = Join-Path $script:tempRoot "action"
        New-Item -Path $actionPath -ItemType Directory -Force | Out-Null
        $runnerPath = Join-Path $actionPath "AlToolTestRunner.psm1"
        @'
function Invoke-AlToolTestRun {
    param(
        [string]$ContainerName,
        [System.Management.Automation.PSCredential]$Credential,
        [string]$ExtensionId,
        [string]$AppName,
        [string]$CompanyName,
        [string]$Tenant,
        [string]$TestType,
        [hashtable[]]$DisabledTests,
        [string]$JUnitResultFileName,
        [string]$CoverageMode,
        [string]$CoverageOutputPath,
        [string[]]$CoverageFormats,
        [string[]]$CoverageSourceRoots,
        [ref]$CoverageIsComplete
    )
    $null = $ContainerName, $Credential, $CompanyName, $Tenant, $TestType, $JUnitResultFileName
    @{
        ExtensionId = $ExtensionId
        AppName = $AppName
        DisabledTests = @($DisabledTests)
        CoverageMode = $CoverageMode
        CoverageOutputPath = $CoverageOutputPath
        CoverageFormats = @($CoverageFormats)
        CoverageSourceRoots = @($CoverageSourceRoots)
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $env:BCAPPS_COVERAGE_CAPTURE_PATH -Encoding UTF8
    $CoverageIsComplete.Value = $true
    return $true
}
Export-ModuleMember -Function Invoke-AlToolTestRun
'@ | Set-Content -LiteralPath $runnerPath -Encoding UTF8

        $script:context = New-TestCoverageContext -Root $script:tempRoot
        $script:context.RunnerModulePath = $runnerPath
        $script:password = New-Object System.Security.SecureString
        foreach ($character in "password".ToCharArray()) {
            $script:password.AppendChar($character)
        }
        $script:credential = New-Object System.Management.Automation.PSCredential("admin", $script:password)
        $env:BCAPPS_COVERAGE_CAPTURE_PATH = Join-Path $script:tempRoot "capture.json"
    }

    AfterEach {
        Remove-Item Env:\BCAPPS_COVERAGE_CAPTURE_PATH -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "imports the running action module and writes only unique worker sidecar metadata" {
        $parameters = @{
            containerName = "test"
            credential = $script:credential
            companyName = "My Company"
            tenant = "tenant2"
            appName = "Test App"
            extensionId = "test-app"
            disabledTests = @(@{ codeunitName = "Configured"; method = @("Skip") })
            JUnitResultFileName = Join-Path $script:tempRoot "results.xml"
            _bcAppsAlToolCoverageContext = $script:context
            _bcAppsAlToolCoverageAppId = "test-app"
            _bcAppsAlToolCoverageAppName = "Test App"
            _bcAppsAlToolCoverageLogicalShard = "normal"
            _bcAppsAlToolCoverageAttempt = 1
            _bcAppsAlToolCoverageTrack = $true
            _bcAppsAlToolCoverageDisabledTests = @(
                @{ codeunitName = "Clean"; method = @("*") }
            )
        }

        $result = Invoke-BcAppsAlToolCoverageLeaf -Parameters $parameters `
            -TestType "IntegrationTest"
        $capturedRun = Get-Content -LiteralPath $env:BCAPPS_COVERAGE_CAPTURE_PATH -Raw | ConvertFrom-Json

        $result.Handled | Should -BeTrue
        $result.Passed | Should -BeTrue
        $capturedRun.ExtensionId | Should -Be "test-app"
        @($capturedRun.DisabledTests | ForEach-Object { $_.codeunitName }) |
            Should -Be @("Configured", "Clean")
        $capturedRun.CoverageMode | Should -Be "line"
        @(Get-ChildItem -LiteralPath $script:context.SidecarRoot -Filter "*.json" -File).Count |
            Should -Be 1
        Test-Path -LiteralPath $script:context.StatusPath | Should -BeFalse
    }

    It "survives background-job serialization used by the tenant scheduler" {
        $parameters = @{
            containerName = "test"
            credential = $script:credential
            companyName = "My Company"
            tenant = "tenant2"
            appName = "Test App"
            extensionId = "test-app"
            disabledTests = @()
            JUnitResultFileName = Join-Path $script:tempRoot "results.xml"
            _bcAppsAlToolCoverageContext = $script:context
            _bcAppsAlToolCoverageAppId = "test-app"
            _bcAppsAlToolCoverageAppName = "Test App"
            _bcAppsAlToolCoverageLogicalShard = "normal"
            _bcAppsAlToolCoverageAttempt = 1
            _bcAppsAlToolCoverageTrack = $true
            _bcAppsAlToolCoverageDisabledTests = @()
        }
        $adapterPath = (Resolve-Path (Join-Path $PSScriptRoot "../AlToolCoverageAdapter.psm1")).Path
        $job = Start-Job -ScriptBlock {
            Import-Module $using:adapterPath -Force
            Invoke-BcAppsAlToolCoverageLeaf -Parameters $using:parameters -TestType "IntegrationTest"
        }

        Wait-Job -Job $job | Out-Null
        $result = Receive-Job -Job $job
        Remove-Job -Job $job -Force

        $result.Handled | Should -BeTrue
        $result.Passed | Should -BeTrue
        @(Get-ChildItem -LiteralPath $script:context.SidecarRoot -Filter "*.json" -File).Count |
            Should -Be 1
        Test-Path -LiteralPath $script:context.StatusPath | Should -BeFalse
    }
}

Describe "AlTool coverage status coordination" {
    BeforeEach {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("coverage-status-" + [guid]::NewGuid().ToString("N"))
        New-Item -Path (Join-Path $script:tempRoot "src\App") -ItemType Directory -Force | Out-Null
        $script:context = New-TestCoverageContext -Root $script:tempRoot
        Register-BcAppsAlToolCoverageShard -Context $script:context -AppId "test-app" `
            -AppName "Test App" -LogicalShard "normal"
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "keeps only the final attempt for each logical shard" {
        $null = Write-TestCoverageSidecar -Context $script:context -LogicalShard "normal" `
            -Attempt 1 -State "failed"
        $finalOutput = Write-TestCoverageSidecar -Context $script:context -LogicalShard "normal" `
            -Attempt 2 -State "complete"

        $completedStatus = Complete-BcAppsAlToolCoverage -Context $script:context

        $status = Get-Content -LiteralPath $script:context.StatusPath -Raw | ConvertFrom-Json
        @($completedStatus.runs).Count | Should -Be 1
        $status.runs.Count | Should -Be 1
        $status.runs[0].state | Should -Be "complete"
        $status.runs[0].outputDirectory | Should -Be $finalOutput.RelativePath
        $status.runs[0].outputDirectory | Should -Not -Match "/1$"
    }

    It "serializes exactly one analyzer status with ordered roots and failed missing shards" {
        Register-BcAppsAlToolCoverageShard -Context $script:context -AppId "test-app" `
            -AppName "Test App" -LogicalShard "clean-50000"
        $null = Write-TestCoverageSidecar -Context $script:context -LogicalShard "normal" `
            -Attempt 1 -State "complete"

        $null = Complete-BcAppsAlToolCoverage -Context $script:context

        @(Get-ChildItem -LiteralPath $script:context.CoverageRoot -Filter "coverage-status.json" -File -Recurse).Count |
            Should -Be 1
        $status = Get-Content -LiteralPath $script:context.StatusPath -Raw | ConvertFrom-Json
        $status.PSObject.Properties.Name | Should -Be @(
            "project", "projectName", "buildMode", "mode", "formats",
            "sourceRoots", "sourceRootDetails", "runs"
        )
        $status.sourceRoots | Should -Be @("src/App")
        $status.sourceRootDetails[0].kind | Should -Be "app"
        @($status.runs | Where-Object { $_.state -eq "failed" }).Count | Should -Be 1
    }

    It "is accepted by the actual AL-Go coverage analyzer fixture" -Skip:(
        [string]::IsNullOrWhiteSpace($env:BCAPPS_ALGO_ANALYZER_PATH) -or
        -not (Test-Path -LiteralPath $env:BCAPPS_ALGO_ANALYZER_PATH -PathType Leaf)
    ) {
        $sourceFile = Join-Path $script:tempRoot "src\App\Line.Codeunit.al"
        1..20 | ForEach-Object { "// line $_" } | Set-Content -LiteralPath $sourceFile -Encoding UTF8
        $output = Write-TestCoverageSidecar -Context $script:context -LogicalShard "normal" `
            -Attempt 1 -State "complete"
        New-Item -Path $output.FullPath -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath (
            Join-Path $PSScriptRoot "TestArtifacts\AlToolCoverageAdapter\coverage.bc.json"
        ) -Destination (Join-Path $output.FullPath "coverage.bc.json")
        $null = Complete-BcAppsAlToolCoverage -Context $script:context

        Import-Module $env:BCAPPS_ALGO_ANALYZER_PATH -Force
        $model = Get-ProjectCoverageModel -CoveragePath (
            Join-Path $script:tempRoot ".buildartifacts"
        ) -RepositoryRoot $script:tempRoot

        $model.Complete | Should -BeTrue -Because (
            @($model.Reasons) + @($model.LineReasons) -join "; "
        )
        $model.LineComplete | Should -BeTrue -Because (
            @($model.Reasons) + @($model.LineReasons) -join "; "
        )
        $model.Runs.Count | Should -Be 1
        $model.Runs[0].OutputDirectory | Should -Be $output.RelativePath
    }
}

Describe "AlTool coverage capability fallback" {
    It "keeps UnitTest and Legacy on their existing runners" -ForEach @(
        @{ TestType = "UnitTest" }
        @{ TestType = "Legacy" }
    ) {
        $capability = Get-BcAppsAlToolCoverageCapability -TestType $TestType `
            -PlatformVersion "30.0.56026.0" -PlatformVersionReason "" `
            -ActionPath $TestDrive -CoverageEnabled $true
        $capability.Supported | Should -BeFalse
        $capability.Reason | Should -Match "only IntegrationTest and Uncategorized"
    }

    It "rejects platforms older than the coverage minimum" {
        $capability = Get-BcAppsAlToolCoverageCapability -TestType "IntegrationTest" `
            -PlatformVersion "30.0.56025.0" -PlatformVersionReason "" `
            -ActionPath $TestDrive -CoverageEnabled $true
        $capability.Supported | Should -BeFalse
        $capability.Reason | Should -Match "older than the required 30.0.56026.0"
    }

    It "does not replace the action-owned unsupported status when the adapter is disabled" {
        $root = Join-Path $TestDrive "fallback"
        $coverageRoot = Join-Path $root "CodeCoverage"
        New-Item -Path $coverageRoot -ItemType Directory -Force | Out-Null
        $statusPath = Join-Path $coverageRoot "coverage-status.json"
        '{"runs":[{"state":"unsupported"}]}' | Set-Content -LiteralPath $statusPath -Encoding UTF8
        $context = @{ Enabled = $false; Reason = "Unavailable"; StatusPath = $statusPath }

        Complete-BcAppsAlToolCoverage -Context $context

        (Get-Content -LiteralPath $statusPath -Raw) | Should -Match '"unsupported"'
    }
}
