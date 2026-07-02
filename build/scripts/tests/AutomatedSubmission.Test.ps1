$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

Describe "AutomatedSubmission" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../AutomatedSubmission.psm1') -Force
    }

    It "does not fail when enabling auto-merge fails after PR creation" {
        function global:gh {
            param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Arguments)

            if ($Arguments[0] -eq 'api') {
                $global:LASTEXITCODE = 0
                return "[]"
            }

            if (($Arguments[0] -eq 'label') -and ($Arguments[1] -eq 'list')) {
                $global:LASTEXITCODE = 0
                return '[{"name":"Automation"}]'
            }

            if (($Arguments[0] -eq 'pr') -and ($Arguments[1] -eq 'create')) {
                $global:LASTEXITCODE = 0
                return "https://github.com/microsoft/BCApps/pull/1"
            }

            if (($Arguments[0] -eq 'pr') -and ($Arguments[1] -eq 'merge')) {
                $global:LASTEXITCODE = 1
                return "Cannot use `-d` or `--delete-branch` when merge queue enabled"
            }

            $global:LASTEXITCODE = 0
            return ""
        }

        try {
            $prLink = New-GitHubPullRequest `
                -Repository "microsoft/BCApps" `
                -BranchName "automation/main/updateappbaselines/2606300521" `
                -TargetBranch "main" `
                -Title "[main] Update package versions" `
                -Description "Test description"

            $prLink | Should -Be "https://github.com/microsoft/BCApps/pull/1"
            $LASTEXITCODE | Should -Be 0
        }
        finally {
            Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
        }
    }
}
