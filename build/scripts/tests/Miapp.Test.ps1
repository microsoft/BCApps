$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot '../Miapp/MicroAppGitHelper.psm1') -Force

Describe "Miapp base branch resolution" {
    BeforeAll {
        $script:originalRepoBranchName = $env:RepoBranchName
        $script:originHeadRef = git symbolic-ref --quiet --short refs/remotes/origin/HEAD
        if ($script:originHeadRef -notmatch '^origin/.+$') {
            throw "Cannot resolve the default branch from origin/HEAD. Actual value: '$script:originHeadRef'."
        }
        $script:defaultBranchName = $script:originHeadRef -replace '^origin/', ''
    }

    AfterEach {
        $env:RepoBranchName = $script:originalRepoBranchName
    }

    It "Should preserve a valid explicit base branch" {
        $env:RepoBranchName = $script:defaultBranchName

        $actualBranchName = Initialize-MiappRepoBranchName
        if ($actualBranchName -ne $script:defaultBranchName) {
            throw "Expected '$script:defaultBranchName', but got '$actualBranchName'."
        }
    }

    It "Should resolve origin HEAD when no base branch is configured" {
        $env:RepoBranchName = $null

        $actualBranchName = Initialize-MiappRepoBranchName
        if ($actualBranchName -ne $script:defaultBranchName) {
            throw "Expected '$script:defaultBranchName', but got '$actualBranchName'."
        }
    }

    It "Should replace a stale base branch from another repository" {
        $env:RepoBranchName = 'branch-that-does-not-exist-on-origin'

        $actualBranchName = Initialize-MiappRepoBranchName -WarningAction SilentlyContinue
        if ($actualBranchName -ne $script:defaultBranchName) {
            throw "Expected '$script:defaultBranchName', but got '$actualBranchName'."
        }
    }
}
