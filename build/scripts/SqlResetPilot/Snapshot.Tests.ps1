BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Comparison.psm1') -Force
}

Describe 'Immutable country package snapshots' {
    BeforeEach {
        $script:proof = @(
            Get-SqlComparisonArtifact | Where-Object country -eq DE | ForEach-Object {
                [PSCustomObject]@{
                    pin = $_
                    metadata = [PSCustomObject]@{
                        id = $_.id; expired = $false; digest = "sha256:$($_.digest)"
                        workflow_run = [PSCustomObject]@{
                            id = 37372848860; head_sha = 'c4953dceffe02a017adad34973e1955017bf5d20'
                        }
                    }
                }
            }
        )
        $script:directory = Join-Path $TestDrive 'snapshot'
        $null = New-Item -ItemType Directory $script:directory -Force
        $script:proof | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $script:directory 'artifact-proof.json')
        Mock Get-FileHash -ModuleName Comparison {
            $pin = Get-SqlComparisonArtifact | Where-Object { $Path -like "*$($_.id).zip" }
            [PSCustomObject]@{ Hash = $pin.digest }
        }
    }
    It 'requires both exact ZIP hashes and original unexpired source provenance' {
        @(Assert-SqlComparisonSnapshot -Directory $script:directory -Country DE).Count | Should -Be 2
        Should -Invoke Get-FileHash -ModuleName Comparison -Times 2 -Exactly
    }
    It 'rejects changed ZIP bytes regardless of correct metadata' {
        Mock Get-FileHash -ModuleName Comparison { [PSCustomObject]@{ Hash = 'wrong' } }
        { Assert-SqlComparisonSnapshot -Directory $script:directory -Country DE } | Should -Throw
    }
    It 'rejects source drift and incomplete or wrong-country snapshots' {
        { Assert-SqlComparisonSnapshot -Directory $script:directory -Country W1 } | Should -Throw
        $script:proof[0].metadata.workflow_run.id = 1
        $script:proof | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $script:directory 'artifact-proof.json')
        { Assert-SqlComparisonSnapshot -Directory $script:directory -Country DE } | Should -Throw
        @($script:proof[1]) | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $script:directory 'artifact-proof.json')
        { Assert-SqlComparisonSnapshot -Directory $script:directory -Country DE } | Should -Throw
    }
    It 'rejects snapshots captured from already-expired original artifacts' {
        $script:proof[0].metadata.expired = $true
        $script:proof | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $script:directory 'artifact-proof.json')
        { Assert-SqlComparisonSnapshot -Directory $script:directory -Country DE } | Should -Throw
    }
}

Describe 'Snapshot download transport and ownership' {
    BeforeEach {
        $script:oldToken = $env:GH_TOKEN
        $env:GH_TOKEN = 'synthetic-test-token'
        $script:metadata = [PSCustomObject]@{
            expired = $false; workflow_run = [PSCustomObject]@{ id = 100; head_sha = 'revision' }
            name = 'sql-api-comparison-packages-DE-100'; digest = ('sha256:' + ('a' * 64))
        }
        Mock Invoke-RestMethod -ModuleName Comparison { $script:metadata }
        Mock Invoke-WebRequest -ModuleName Comparison {}
        Mock Get-FileHash -ModuleName Comparison { [PSCustomObject]@{ Hash = ('a' * 64) } }
        Mock Expand-Archive -ModuleName Comparison {}
        Mock Assert-SqlComparisonSnapshot -ModuleName Comparison { 'validated' }
    }
    AfterEach { $env:GH_TOKEN = $script:oldToken }
    It 'validates owned immutable transport before extracting and checking source ZIPs' {
        Save-SqlComparisonSnapshot -ArtifactId 200 -RunId 100 -HeadSha revision -Country DE `
            -Directory (Join-Path $TestDrive 'snapshot') | Should -Be 'validated'
        Should -Invoke Invoke-WebRequest -ModuleName Comparison -Times 1 -Exactly
        Should -Invoke Expand-Archive -ModuleName Comparison -Times 1 -Exactly
        Should -Invoke Assert-SqlComparisonSnapshot -ModuleName Comparison -Times 1 -Exactly
    }
    It 'rejects wrong run, head, name or expired snapshot before download' {
        { Save-SqlComparisonSnapshot 200 101 revision DE (Join-Path $TestDrive 'snapshot') } | Should -Throw
        { Save-SqlComparisonSnapshot 200 100 different DE (Join-Path $TestDrive 'snapshot') } | Should -Throw
        { Save-SqlComparisonSnapshot 200 100 revision W1 (Join-Path $TestDrive 'snapshot') } | Should -Throw
        $script:metadata.expired = $true
        { Save-SqlComparisonSnapshot 200 100 revision DE (Join-Path $TestDrive 'snapshot') } | Should -Throw
        Should -Invoke Invoke-WebRequest -ModuleName Comparison -Times 0
    }
    It 'never extracts a corrupt transport archive' {
        Mock Get-FileHash -ModuleName Comparison { [PSCustomObject]@{ Hash = 'corrupted' } }
        { Save-SqlComparisonSnapshot 200 100 revision DE (Join-Path $TestDrive 'snapshot') } | Should -Throw
        Should -Invoke Expand-Archive -ModuleName Comparison -Times 0
    }
}
