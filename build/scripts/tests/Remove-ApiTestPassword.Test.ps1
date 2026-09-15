Describe 'API test credential cleanup' {
    BeforeAll {
        $script:cleanupScript = Join-Path $PSScriptRoot '..\Remove-ApiTestPassword.ps1'
        $script:passwordPath = Join-Path $PSScriptRoot 'unused\ApiTestPassword'
        $script:previousExitCode = Get-Variable -Name LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
        function docker {
            param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
            $null = $Arguments
            throw 'Docker must be mocked; these tests never contact a container.'
        }
    }

    AfterAll {
        $global:LASTEXITCODE = $script:previousExitCode
    }

    BeforeEach {
        $script:events = [System.Collections.Generic.List[string]]::new()
        Mock Test-Path { $true }
        Mock docker {
            $global:LASTEXITCODE = 0
            if ($Arguments[0] -eq 'container') {
                'test-container-id'
            }
            else {
                $script:events.Add('stop')
            }
        }
        Mock Remove-Item { $script:events.Add('delete') }
    }

    It 'stops all consumers before deleting the exact backing file' {
        . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath

        ($script:events -join ',') | Should -Be 'stop,delete'
        Should -Invoke docker -Times 1 -Exactly -ParameterFilter {
            $Arguments[0] -eq 'container' -and $Arguments -contains '--all' -and
            $Arguments -contains 'name=^/test-container$'
        }
        Should -Invoke Remove-Item -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq $script:passwordPath -and $Force -and $ErrorAction -eq 'Stop'
        }
    }

    It 'does nothing when the password file is missing' {
        Mock Test-Path { $false }

        . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath

        Should -Invoke docker -Times 0
        Should -Invoke Remove-Item -Times 0
    }

    It 'removes a leftover backing file when the container is already absent' {
        Mock docker { $global:LASTEXITCODE = 0 }

        . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath

        ($script:events -join ',') | Should -Be 'delete'
        Should -Invoke docker -Times 0 -ParameterFilter { $Arguments[0] -eq 'stop' }
    }

    It 'also stops an already-stopped container idempotently before deletion' {
        . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath

        Should -Invoke docker -Times 1 -Exactly -ParameterFilter {
            ($Arguments -join ' ') -eq 'stop --time 30 test-container-id'
        }
        Should -Invoke Remove-Item -Times 1 -Exactly
    }

    It 'fails without deleting when Docker cannot enumerate containers' {
        Mock docker { $global:LASTEXITCODE = 1 }

        { . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath } |
            Should -Throw '*Could not determine*'
        Should -Invoke Remove-Item -Times 0
    }

    It 'fails without deleting while consumers cannot be stopped' {
        Mock docker { $global:LASTEXITCODE = 1 } -ParameterFilter { $Arguments[0] -eq 'stop' }

        { . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath } |
            Should -Throw '*Could not stop API test consumers*'
        Should -Invoke Remove-Item -Times 0
    }

    It 'fails without stopping or deleting if container identity is ambiguous' {
        Mock docker {
            $global:LASTEXITCODE = 0
            'first-id', 'second-id'
        }

        { . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath } |
            Should -Throw '*more than one container*'
        Should -Invoke docker -Times 0 -ParameterFilter { $Arguments[0] -eq 'stop' }
        Should -Invoke Remove-Item -Times 0
    }

    It 'surfaces deletion failure rather than reporting successful cleanup' {
        Mock Remove-Item { throw 'Access denied' }

        { . $script:cleanupScript -ContainerName 'test-container' -FilePath $script:passwordPath } |
            Should -Throw '*Access denied*'
    }

    It 'rejects a path that does not name the credential file' {
        { . $script:cleanupScript -ContainerName 'test-container' -FilePath (Join-Path $TestDrive 'other-file') } |
            Should -Throw '*exact ApiTestPassword file*'
        Should -Invoke docker -Times 0
        Should -Invoke Remove-Item -Times 0
    }
}

Describe 'API test credential workflow lifetime' {
    BeforeAll {
        $script:workflow = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\..\.github\workflows\_BuildALGoProject.yaml') -Raw
        $script:setup = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\NewBcContainer.ps1') -Raw
    }

    It 'delegates credential materialization without host or container staging copies' {
        $script:setup | Should -Match "Import-Module .*'ApiTestCredential.psm1'"
        $script:setup | Should -Match 'Write-ApiTestPassword -ContainerName \$parameters.ContainerName -Credential \$parameters.credential'
        $script:setup | Should -Not -Match 'Copy-FileToBcContainer|WriteAllText|GetNetworkCredential|GetTempPath'
    }

    It 'runs cleanup on success, failure and cancellation after all build consumers' {
        $cleanupStep = [regex]::Match($script:workflow, '(?ms)^      - name: Remove API test credential\r?\n.*?(?=^      - name: Cleanup)').Value
        $cleanupStep | Should -Match "if: always\(\) && steps\.DetermineBuildProject\.outputs\.BuildIt == 'True' && env\.BCAppsApiTestPasswordPath != ''"
        $cleanupStep | Should -Match 'timeout-minutes: 2'
        $cleanupStep | Should -Match 'Remove-ApiTestPassword.ps1'
        $cleanupStep | Should -Not -Match 'continue-on-error'
        $script:workflow.IndexOf('- name: Build') |
            Should -BeLessThan $script:workflow.IndexOf('- name: Remove API test credential')
        $script:workflow | Should -Match '(?s)- name: Cleanup\r?\n\s+if: always\(\).*?uses: microsoft/AL-Go/Actions/PipelineCleanup@'
    }
}
