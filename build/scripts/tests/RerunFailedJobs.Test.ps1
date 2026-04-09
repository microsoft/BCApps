$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

# Determine the script root directory
$testsDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $testsDir) { $testsDir = $PWD.Path + "/build/scripts/tests" }

# Load the action script as a module for testing by extracting functions
$actionScript = Join-Path $testsDir ".." ".." ".." ".github" "actions" "RerunFailedJobs" "action.ps1"

Describe "RerunFailedJobs Action" {
    BeforeAll {
        # Mock environment variables
        $env:GITHUB_REPOSITORY = "microsoft/BCApps"
        $env:GITHUB_STEP_SUMMARY = ""

        # Determine the script root directory
        $testsDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        if (-not $testsDir) { $testsDir = $PWD.Path + "/build/scripts/tests" }

        $actionScript = Join-Path $testsDir ".." ".." ".." ".github" "actions" "RerunFailedJobs" "action.ps1"

        # Source functions from the action script by extracting function definitions
        $scriptContent = Get-Content $actionScript -Raw

        # Extract all function definitions and execute them in this scope
        $functionPattern = '(?ms)(function\s+[\w-]+\s*\{(?:[^{}]|\{(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*\})*\})'
        $matches = [regex]::Matches($scriptContent, $functionPattern)
        foreach ($match in $matches) {
            Invoke-Expression $match.Value
        }
    }

    AfterAll {
        Remove-Item Env:\GITHUB_REPOSITORY -ErrorAction SilentlyContinue
        Remove-Item Env:\GITHUB_STEP_SUMMARY -ErrorAction SilentlyContinue
    }

    Context "Get-WorkflowRun" {
        It "should call the GitHub API with the correct run ID" {
            $mockRun = @{
                id          = 12345
                run_attempt = 1
            } | ConvertTo-Json

            Mock gh { return $mockRun } -ParameterFilter { $args -contains "/repos/microsoft/BCApps/actions/runs/12345" }

            $result = Get-WorkflowRun -RunId "12345"

            $result.id | Should -Be 12345
            $result.run_attempt | Should -Be 1
        }
    }

    Context "Get-FailedJobs" {
        It "should return only failed jobs" {
            $mockResponse = @{
                total_count = 3
                jobs        = @(
                    @{ id = 1; name = "Build App1"; conclusion = "failure" },
                    @{ id = 2; name = "Build App2"; conclusion = "success" },
                    @{ id = 3; name = "Build App3"; conclusion = "failure" }
                )
            } | ConvertTo-Json -Depth 3

            Mock gh { return $mockResponse }

            $result = Get-FailedJobs -RunId "12345"

            $result.Count | Should -Be 2
            $result[0].name | Should -Be "Build App1"
            $result[1].name | Should -Be "Build App3"
        }

        It "should return empty array when no jobs failed" {
            $mockResponse = @{
                total_count = 2
                jobs        = @(
                    @{ id = 1; name = "Build App1"; conclusion = "success" },
                    @{ id = 2; name = "Build App2"; conclusion = "success" }
                )
            } | ConvertTo-Json -Depth 3

            Mock gh { return $mockResponse }

            $result = Get-FailedJobs -RunId "12345"

            @($result).Count | Should -Be 0
        }

        It "should handle pagination for large number of jobs" {
            $page1Response = @{
                total_count = 150
                jobs        = @(1..100 | ForEach-Object {
                        @{ id = $_; name = "Job $_"; conclusion = if ($_ -eq 50) { "failure" } else { "success" } }
                    })
            } | ConvertTo-Json -Depth 3

            $page2Response = @{
                total_count = 150
                jobs        = @(101..150 | ForEach-Object {
                        @{ id = $_; name = "Job $_"; conclusion = if ($_ -eq 120) { "failure" } else { "success" } }
                    })
            } | ConvertTo-Json -Depth 3

            $script:callCount = 0
            Mock gh {
                $script:callCount++
                if ($script:callCount -eq 1) { return $page1Response }
                else { return $page2Response }
            }

            $result = Get-FailedJobs -RunId "12345"

            $result.Count | Should -Be 2
        }
    }

    Context "Get-JobLogs" {
        It "should return truncated logs when log output exceeds 200 lines" {
            $longLog = (1..300 | ForEach-Object { "Log line $_" }) -join "`n"

            Mock gh { return $longLog }
            $global:LASTEXITCODE = 0

            $result = Get-JobLogs -JobId "999"
            $lines = $result -split "`n"

            $lines.Count | Should -Be 200
        }

        It "should return full logs when under 200 lines" {
            $shortLog = (1..50 | ForEach-Object { "Log line $_" }) -join "`n"

            Mock gh { return $shortLog }
            $global:LASTEXITCODE = 0

            $result = Get-JobLogs -JobId "999"
            $lines = $result -split "`n"

            $lines.Count | Should -Be 50
        }

        It "should return empty string when logs cannot be fetched" {
            Mock gh { $global:LASTEXITCODE = 1; return "Not Found" }

            $result = Get-JobLogs -JobId "999"

            $result | Should -Be ""
        }
    }

    Context "Get-InstabilityAnalysis" {
        It "should return instability when AI detects a transient failure" {
            $mockResponse = @{
                choices = @(
                    @{
                        message = @{
                            content = '{"isInstability": true, "reason": "Docker container timeout"}'
                        }
                    }
                )
            } | ConvertTo-Json -Depth 5

            Mock gh { return $mockResponse }

            $result = Get-InstabilityAnalysis -JobName "Build App1" -Logs "Error: container health check timeout"

            $result.IsInstability | Should -Be $true
            $result.Reason | Should -Be "Docker container timeout"
        }

        It "should return non-instability when AI detects a genuine failure" {
            $mockResponse = @{
                choices = @(
                    @{
                        message = @{
                            content = '{"isInstability": false, "reason": "AL compilation error in codeunit 50100"}'
                        }
                    }
                )
            } | ConvertTo-Json -Depth 5

            Mock gh { return $mockResponse }

            $result = Get-InstabilityAnalysis -JobName "Build App1" -Logs "Error AL0001: syntax error"

            $result.IsInstability | Should -Be $false
            $result.Reason | Should -Be "AL compilation error in codeunit 50100"
        }

        It "should handle markdown-wrapped JSON response from AI" {
            $mockResponse = @{
                choices = @(
                    @{
                        message = @{
                            content = "``````json`n{""isInstability"": true, ""reason"": ""Network timeout""}`n``````"
                        }
                    }
                )
            } | ConvertTo-Json -Depth 5

            Mock gh { return $mockResponse }

            $result = Get-InstabilityAnalysis -JobName "Build App1" -Logs "Error: connection timeout"

            $result.IsInstability | Should -Be $true
            $result.Reason | Should -Be "Network timeout"
        }

        It "should return non-instability when AI call fails" {
            Mock gh { throw "API Error" }

            $result = Get-InstabilityAnalysis -JobName "Build App1" -Logs "Some error"

            $result.IsInstability | Should -Be $false
            $result.Reason | Should -Match "AI analysis failed"
        }
    }

    Context "Add-PRComment" {
        It "should post a comment to the correct PR" {
            $run = @{
                pull_requests = @(
                    @{ number = 42 }
                )
            }

            Mock gh { return '{"id": 1}' }

            Add-PRComment -Run $run -Comment "Test comment"

            Should -Invoke gh -Times 1 -ParameterFilter {
                $args -contains "/repos/microsoft/BCApps/issues/42/comments"
            }
        }

        It "should skip posting when no PR number is found" {
            $run = @{
                pull_requests = @()
            }

            Mock gh {}

            Add-PRComment -Run $run -Comment "Test comment"

            Should -Invoke gh -Times 0
        }
    }
}
