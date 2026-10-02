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

    It 'leaves generated workflow cleanup unmodified and uses supported project finalizers' {
        $script:workflow | Should -Not -Match '- name: Remove API test credential|Remove-ApiTestPassword.ps1'
        $script:workflow | Should -Match '(?s)- name: Cleanup\r?\n\s+if: always\(\).*?uses: microsoft/AL-Go/Actions/PipelineCleanup@'
        & (Join-Path $PSScriptRoot '..\Update-TestProjectPipelineFinalize.ps1') -Check
    }
}

Describe 'API test credential pipeline finalizer' {
    BeforeAll {
        $script:finalizer = Join-Path $PSScriptRoot '..\PipelineFinalize.ps1'
        $script:previousPasswordPath = $env:BCAppsApiTestPasswordPath
        $script:previousPasswordContainer = $env:BCAppsApiTestPasswordContainer
        $script:previousExitCode = Get-Variable LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
        function docker {
            param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
            $null = $Arguments
            throw 'Docker must be mocked.'
        }
    }

    BeforeEach {
        $env:BCAppsApiTestPasswordPath = Join-Path $TestDrive 'ApiTestPassword'
        $env:BCAppsApiTestPasswordContainer = 'recorded-container'
        Mock Test-Path { $true }
        Mock docker {
            $global:LASTEXITCODE = 0
            if ($Arguments[0] -eq 'container') { 'recorded-container-id' }
        }
        Mock Remove-Item {
            Should -Invoke docker -Times 1 -ParameterFilter { $Arguments[0] -eq 'stop' }
        }
        Mock Write-Host {}
    }

    AfterAll {
        $env:BCAppsApiTestPasswordPath = $script:previousPasswordPath
        $env:BCAppsApiTestPasswordContainer = $script:previousPasswordContainer
        $global:LASTEXITCODE = $script:previousExitCode
    }

    It 'accepts no arguments and stops the recorded consumers before deleting the backing file' {
        $path = $env:BCAppsApiTestPasswordPath
        . $script:finalizer
        Should -Invoke docker -Times 1 -Exactly -ParameterFilter {
            $Arguments -contains 'name=^/recorded-container$'
        }
        Should -Invoke Remove-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $path }
        $env:BCAppsApiTestPasswordPath | Should -BeNullOrEmpty
        $env:BCAppsApiTestPasswordContainer | Should -BeNullOrEmpty
    }

    It 'does nothing when no credential was provisioned' {
        $env:BCAppsApiTestPasswordPath = $null
        . $script:finalizer
        Should -Invoke docker -Times 0
        Should -Invoke Remove-Item -Times 0
    }

    It 'is idempotent when standard teardown already removed the credential' {
        Mock Test-Path { $false }
        . $script:finalizer
        . $script:finalizer
        Should -Invoke docker -Times 0
        Should -Invoke Remove-Item -Times 0
        $env:BCAppsApiTestPasswordPath | Should -BeNullOrEmpty
    }

    It 'preserves cleanup identity and propagates a failure without deleting while consumers remain' {
        Mock docker { $global:LASTEXITCODE = 1 } -ParameterFilter { $Arguments[0] -eq 'stop' }
        { . $script:finalizer } | Should -Throw '*Could not stop API test consumers*'
        Should -Invoke Remove-Item -Times 0
        $env:BCAppsApiTestPasswordContainer | Should -Be 'recorded-container'
        $env:BCAppsApiTestPasswordPath | Should -Be (Join-Path $TestDrive 'ApiTestPassword')
    }

    It 'propagates deletion failure without forgetting the recorded path' {
        Mock Remove-Item { throw 'Synthetic deletion failure' }
        { . $script:finalizer } | Should -Throw '*Synthetic deletion failure*'
        $env:BCAppsApiTestPasswordPath | Should -Be (Join-Path $TestDrive 'ApiTestPassword')
    }

    It 'runs every registered project wrapper through the AL-Go scriptblock invocation contract' {
        $projects = Join-Path $PSScriptRoot '..\..\projects'
        $wrappers = @(Get-ChildItem -LiteralPath $projects -Directory | ForEach-Object {
            $setup = Join-Path $_.FullName '.AL-Go\NewBcContainer.ps1'
            if ([IO.File]::Exists($setup)) {
                Get-Item -LiteralPath (Join-Path $_.FullName '.AL-Go\PipelineFinalize.ps1')
            }
        })
        $wrappers.Count | Should -BeGreaterThan 0
        foreach ($wrapper in $wrappers) {
            $env:BCAppsApiTestPasswordPath = Join-Path $TestDrive 'ApiTestPassword'
            $env:BCAppsApiTestPasswordContainer = 'recorded-container'
            Invoke-Command -ScriptBlock (Get-Command $wrapper.FullName).ScriptBlock
        }
        Should -Invoke Remove-Item -Times $wrappers.Count -Exactly
    }
}

Describe 'API test pipeline finalizer generation' {
    BeforeAll {
        $script:generator = Join-Path $PSScriptRoot '..\Update-TestProjectPipelineFinalize.ps1'
    }

    It 'generates only container-project wrappers and is stable when regenerated' {
        $projects = Join-Path $TestDrive 'projects'
        foreach ($name in @('Test Apps W1', 'Test Apps AT', 'Apps W1')) {
            New-Item -Path (Join-Path $projects "$name\.AL-Go") -ItemType Directory -Force | Out-Null
        }
        foreach ($name in @('Test Apps W1', 'Test Apps AT')) {
            Set-Content -LiteralPath (Join-Path $projects "$name\.AL-Go\NewBcContainer.ps1") -Value 'fixture'
        }
        & $script:generator -ProjectsPath $projects
        $path = Join-Path $projects 'Test Apps W1\.AL-Go\PipelineFinalize.ps1'
        $first = [IO.File]::ReadAllBytes($path)
        & $script:generator -ProjectsPath $projects
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) | Should -Be ([Convert]::ToBase64String($first))
        & $script:generator -ProjectsPath $projects -Check
        Test-Path (Join-Path $projects 'Apps W1\.AL-Go\PipelineFinalize.ps1') | Should -BeFalse
    }

    It 'fails check-only validation for a missing wrapper without writing it' {
        $projects = Join-Path $TestDrive 'missing'
        $folder = Join-Path $projects 'Test Apps W1\.AL-Go'
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $folder 'NewBcContainer.ps1') -Value 'fixture'
        { & $script:generator -ProjectsPath $projects -Check } | Should -Throw '*missing or outdated*'
        Test-Path (Join-Path $folder 'PipelineFinalize.ps1') | Should -BeFalse
    }
}
