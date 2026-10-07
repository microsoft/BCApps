BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $script:workflow = Get-Content (Join-Path $script:root '.github\workflows\CICD.yaml') -Raw
}
Describe 'Single communication-failed DE3 replacement' {
    It 'has exactly one DE3 matrix cell and no automatic event' {
        $script:workflow | Should -Match 'matrix:\s+country: \[DE\]\s+trial: \[3\]\s+runs-on:'
        $script:workflow | Should -Match 'max-parallel: 1'
        $script:workflow | Should -Match 'on:\s+workflow_dispatch:\s+permissions:'
        $script:workflow | Should -Match "github.repository == 'microsoft/BCApps'"
        $script:workflow | Should -Match "github.event_name == 'workflow_dispatch'"
        $script:workflow | Should -Match "github.ref == 'refs/heads/features/646383-sql-api-de3-communication-replay' && github.run_attempt == 1"
    }
    It 'keeps the exact original treatment, settings, cleanup, packages and AL source' {
        $paths = @('src', '.github/AL-Go-Settings.json', '.github/workflows/_BuildALGoProject.yaml',
            'build/projects', 'build/scripts/ParallelTestExecution.psm1',
            'build/scripts/RunTestsInBcContainer.ps1', 'build/scripts/SqlResetPilot/Lifecycle.psm1',
            'build/scripts/SqlResetPilot/Finalize.ps1')
        $diff = & git -C $script:root diff fcc1776c6b165199dd66e4227675b1cc31da7a8f -- @paths
        $LASTEXITCODE | Should -Be 0
        $diff | Should -BeNullOrEmpty
    }
    It 'records original failure identity without claiming a rerun success' {
        $prepare = Get-Content (Join-Path $PSScriptRoot 'Prepare.ps1') -Raw
        $prepare | Should -Match "runId = '37608087700'; jobId = '112748402288'"
        $prepare | Should -Match "workflowSha = 'fcc1776c6b165199dd66e4227675b1cc31da7a8f'"
        $prepare | Should -Match "event = 'workflow_dispatch'; runAttempt = 1"
        $prepare | Should -Match "BC_SQL_PILOT_COUNTRY -ne 'DE'"
        $prepare | Should -Match "BC_SQL_PILOT_TRIAL -ne '3'"
        $prepare | Should -Match 'retries = 0'
    }
    It 'prevents accidental broad PR initialization for the new branch' {
        Get-Content (Join-Path $script:root '.github\workflows\PullRequestHandler.yaml') -Raw |
            Should -Match "github.head_ref != 'features/646383-sql-api-de3-communication-replay'"
    }
}
