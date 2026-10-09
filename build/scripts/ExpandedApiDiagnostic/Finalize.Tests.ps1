BeforeAll {
    $script:fixture = Join-Path $PSScriptRoot ".finalize-$([guid]::NewGuid().ToString('N'))"
    $script:saved = @{}
    foreach ($key in @('GITHUB_WORKSPACE','GITHUB_REPOSITORY','GITHUB_REF','GITHUB_EVENT_NAME','GITHUB_RUN_ATTEMPT',
        'GITHUB_RUN_ID','GITHUB_SHA','BC_EXPANDED_COUNTRY','BC_EXPANDED_CONFIG','BC_EXPANDED_LANE','BC_EXPANDED_PIPELINE_OUTCOME')) {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key)
    }
    $env:GITHUB_WORKSPACE = $fixture
    $env:GITHUB_REPOSITORY = 'microsoft/BCApps'
    $env:GITHUB_REF = 'refs/heads/features/653393-expanded-api-reuse-successor'
    $env:GITHUB_EVENT_NAME = 'workflow_dispatch'; $env:GITHUB_RUN_ATTEMPT = '1'
    $env:GITHUB_RUN_ID = '999'; $env:GITHUB_SHA = 'a'*40
    $env:BC_EXPANDED_COUNTRY = 'W1'; $env:BC_EXPANDED_CONFIG = 'm1w1'; $env:BC_EXPANDED_LANE = 'Default'
}
AfterAll {
    foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}
Describe 'Pre-execution finalization does not manufacture runtime proof' {
    BeforeEach {
        if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
        $script:output = Join-Path $fixture 'expanded-api-output'
        $null = New-Item -ItemType Directory -Path $output -Force
    }
    It 'records setup-invalid and missing evidence when ReadSettings fails before pipeline' {
        $env:BC_EXPANDED_PIPELINE_OUTCOME = 'skipped'
        Set-Content (Join-Path $output 'clock.json') '{"ticks":1}'
        { & (Join-Path $PSScriptRoot 'Finalize.ps1') } | Should -Throw '*Setup invalid*'
        $report = Get-Content (Join-Path $output 'lane-evidence.json') -Raw | ConvertFrom-Json
        $report.qualified | Should -BeFalse
        $report.setupInvalid | Should -BeTrue
        $report.executionState | Should -Be 'execution-not-started'
        $report.missingEvidence | Should -Contain 'phases.jsonl'
        $report.missingEvidence | Should -Not -Contain 'clock.json'
        $report.ownershipReceiptPresent | Should -BeFalse
        $report.containerAbsenceVerified | Should -BeNullOrEmpty
        $report.ownedCleanupVerified | Should -BeNullOrEmpty
        $report.evidence | Should -BeNullOrEmpty
        foreach ($name in @('phases.jsonl','performance.json','cleanup.json')) { Test-Path (Join-Path $output $name) | Should -BeFalse }
    }
    It 'does not infer execution-not-started from missing files if pipeline may have started' {
        $env:BC_EXPANDED_PIPELINE_OUTCOME = 'failure'
        { & (Join-Path $PSScriptRoot 'Finalize.ps1') } | Should -Throw '*Setup invalid*'
        $report = Get-Content (Join-Path $output 'lane-evidence.json') -Raw | ConvertFrom-Json
        $report.executionState | Should -Be 'execution-evidence-incomplete'
        $report.missingEvidence | Should -Contain 'clock.json'
        $report.containerAbsenceVerified | Should -BeNullOrEmpty
    }
}
