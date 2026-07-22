$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force

Describe "Test-TransientTestFailure" {
    It "returns false for null input" {
        Test-TransientTestFailure -Output $null | Should -Be $false
    }

    It "returns false for empty input" {
        Test-TransientTestFailure -Output '' | Should -Be $false
    }

    It "returns false for unrelated output" {
        Test-TransientTestFailure -Output 'All tests passed. No failures detected.' | Should -Be $false
    }

    It "returns true for 'Cannot open page 130455'" {
        Test-TransientTestFailure -Output 'Cannot open page 130455 because it is not found in the system.' | Should -Be $true
    }

    It "returns true for 'InvokeInteractions failed with status code 500'" {
        Test-TransientTestFailure -Output 'InvokeInteractions failed with status code 500' | Should -Be $true
    }

    It "returns true for InteractionManager stack frame" {
        Test-TransientTestFailure -Output 'at InteractionManager.cs:line 203' | Should -Be $true
    }

    It "returns true for 'ClientSession State is InError'" {
        Test-TransientTestFailure -Output 'Exception occurred while running tests: ClientSession State is InError (Wait time 20 seconds) / ' | Should -Be $true
    }

    It "returns true when 'ClientSession State is InError' appears among other output lines" {
        $multiline = @(
            'BcContainerHelper version 6.1.15-preview'
            'Running on Windows, PowerShell 7.6.3'
            'Exception occurred while running tests: ClientSession State is InError (Wait time 20 seconds) / '
            'Tests failed after 1 attempts.'
        ) -join "`n"
        Test-TransientTestFailure -Output $multiline | Should -Be $true
    }
}

Describe "ParallelTestExecution app-name resolution" {
    BeforeAll {
        # Get-BcContainerAppInfo comes from BcContainerHelper, which is present when the module
        # runs inside a BC container but is NOT loaded in the "Run PS Tests" runner. Pester cannot
        # mock a command that does not exist, so define a no-op stub (guarded so we never shadow the
        # real cmdlet) declaring the parameters the module passes, letting the mock bind correctly.
        $script:createdBcContainerAppInfoStub = $false
        if (-not (Get-Command Get-BcContainerAppInfo -ErrorAction SilentlyContinue)) {
            function global:Get-BcContainerAppInfo {
                param(
                    [string]$containerName,
                    [string]$tenant,
                    [switch]$tenantSpecificProperties
                )
                # The parameters exist only so the stub matches the mocked BcContainerHelper cmdlet
                # signature; reference them so PSScriptAnalyzer does not flag them as unused.
                $null = $containerName, $tenant, $tenantSpecificProperties
                # This body must never run: it exists only so Pester can resolve and mock the
                # command. Every module call to it in these tests is intercepted by Pester's mock.
                throw "Get-BcContainerAppInfo stub should never be called; a Pester mock must intercept it."
            }
            $script:createdBcContainerAppInfoStub = $true
        }

        # Create real app.json files on disk so Get-AppNameFromMetadata can read them.
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("patest_" + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null

        function New-AppJson {
            param([string]$Folder, [string]$Name)
            $dir = Join-Path $script:tempRoot $Folder
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $path = Join-Path $dir 'app.json'
            @{ name = $Name; id = [System.Guid]::NewGuid().ToString() } | ConvertTo-Json | Set-Content -Path $path -Encoding utf8
            return $path
        }

        # A metadata record whose projects.json key (ApplicationName) differs from its app.json name.
        $script:mismatchAppJson = New-AppJson -Folder 'Mismatch' -Name 'Real App Name'
        # A metadata record whose key and app.json name agree.
        $script:matchAppJson = New-AppJson -Folder 'Match' -Name 'Aligned Tests'
    }

    AfterAll {
        if ($script:createdBcContainerAppInfoStub -and (Test-Path 'function:global:Get-BcContainerAppInfo')) {
            Remove-Item 'function:global:Get-BcContainerAppInfo' -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $script:tempRoot) { Remove-Item $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Context "Get-AppNameFromMetadata" {
        It "returns the app.json name when it differs from the projects.json key" {
            $md = [PSCustomObject]@{ ApplicationName = 'Projects-Json-Key'; AppJsonPath = $script:mismatchAppJson }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Real App Name'
        }

        It "returns the app.json name when it matches the projects.json key" {
            $md = [PSCustomObject]@{ ApplicationName = 'Aligned Tests'; AppJsonPath = $script:matchAppJson }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Aligned Tests'
        }

        It "falls back to ApplicationName when the app.json path is missing" {
            $md = [PSCustomObject]@{ ApplicationName = 'Fallback Name'; AppJsonPath = (Join-Path $script:tempRoot 'does-not-exist\app.json') }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Fallback Name'
        }

        It "falls back to ApplicationName when AppJsonPath is empty" {
            $md = [PSCustomObject]@{ ApplicationName = 'Fallback Name'; AppJsonPath = '' }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Fallback Name'
        }
    }

    Context "Get-InstalledTestAppNames resilience to key/name drift" {
        It "dispatches a test app whose projects.json key differs from its installed (app.json) name" {
            Mock -ModuleName ParallelTestExecution -CommandName Get-ApplicationGroup -MockWith {
                @(
                    [PSCustomObject]@{ IsTest = $true;  ApplicationName = 'Projects-Json-Key'; AppJsonPath = $script:mismatchAppJson }
                    [PSCustomObject]@{ IsTest = $true;  ApplicationName = 'Aligned Tests';     AppJsonPath = $script:matchAppJson }
                    [PSCustomObject]@{ IsTest = $false; ApplicationName = 'Some Prod App';     AppJsonPath = $null }
                )
            }
            Mock -ModuleName ParallelTestExecution -CommandName Get-BcContainerAppInfo -MockWith {
                @(
                    [PSCustomObject]@{ IsInstalled = $true; Name = 'Real App Name' }   # installed under the app.json name
                    [PSCustomObject]@{ IsInstalled = $true; Name = 'Aligned Tests' }
                )
            }

            $result = Get-InstalledTestAppNames -ContainerName 'c' -Tenant 'default' -Country 'w1'

            $result | Should -Contain 'Real App Name'
            $result | Should -Contain 'Aligned Tests'
            $result | Should -Not -Contain 'Projects-Json-Key'
        }
    }
}
