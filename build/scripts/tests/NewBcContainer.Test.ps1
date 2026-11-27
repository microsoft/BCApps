[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Container command signatures are used by Pester mocks.')]
param()

Describe 'US container compilation settings' {
    BeforeAll {
        $script:containerScript = Join-Path $PSScriptRoot '..\NewBcContainer.ps1'
        function Get-ALGoSetting { param($Key) }
        function Get-ConfigValue { param($Key, $ConfigType) }
        function New-BcContainer {}
        function Set-BcContainerServerConfiguration { param($containerName, $keyName, $keyValue) }
        function Restart-BcContainer { param($containerName) }
        function Get-BcContainerAppInfo { param($containerName, [switch]$tenantSpecificProperties, $sort) }
        function Invoke-ScriptInBcContainer { param($containerName, $scriptblock) }
        function Get-NAVServerInstance {}
        function Get-NAVServerConfiguration {
            param([Parameter(ValueFromPipeline)]$ServerInstance, $KeyName, [switch]$InMemory)
            process {}
        }
    }

    BeforeEach {
        $events = [System.Collections.Generic.List[string]]::new()
        $effective = @{
            ClrRetrieverKind = 'OneApplicationOneAssembly'
            EnableMultithreadedCompilation = 'false'
        }
        $written = @{}
        Mock Import-Module {}
        Mock Get-ConfigValue { @{ Version = $null } }
        Mock Get-ALGoSetting { 'US' }
        Mock New-BcContainer {}
        Mock Write-Host {}
        Mock Get-NAVServerInstance { 'BC' }
        Mock Get-NAVServerConfiguration {
            $events.Add("Read:$KeyName")
            [PSCustomObject]@{ Key = $KeyName; Value = $effective[$KeyName] }
        }
        Mock Invoke-ScriptInBcContainer { & $scriptblock }
        Mock Set-BcContainerServerConfiguration {
            if ($keyName -in @('ClrRetrieverKind', 'EnableMultithreadedCompilation')) {
                $events.Add("Set:$keyName")
                $written[$keyName] = $keyValue
            }
        }
        Mock Restart-BcContainer {
            $events.Add('Restart')
            foreach ($key in $written.Keys) {
                $effective[$key] = $written[$key]
            }
        }
        Mock Get-BcContainerAppInfo { $events.Add('AppInfo') }
    }

    It 'sets only the two US values before restart and verifies effective values before app removal (<Country>)' -ForEach @(
        @{ Country = 'US' }
        @{ Country = 'us' }
    ) {
        Mock Get-ALGoSetting { $Country }

        & $script:containerScript -parameters @{ ContainerName = 'test' }

        ($events -join ',') | Should -Be 'Read:ClrRetrieverKind,Read:EnableMultithreadedCompilation,Set:ClrRetrieverKind,Set:EnableMultithreadedCompilation,Restart,Read:ClrRetrieverKind,Read:EnableMultithreadedCompilation,AppInfo,AppInfo'
        Should -Invoke Set-BcContainerServerConfiguration -Times 1 -Exactly -ParameterFilter {
            $containerName -eq 'test' -and $keyName -eq 'ClrRetrieverKind' -and $keyValue -eq 'OneApplicationMultipleAssemblies'
        }
        Should -Invoke Set-BcContainerServerConfiguration -Times 1 -Exactly -ParameterFilter {
            $containerName -eq 'test' -and $keyName -eq 'EnableMultithreadedCompilation' -and $keyValue -eq 'true'
        }
        Should -Invoke Get-NAVServerConfiguration -Times 4 -Exactly -ParameterFilter {
            $InMemory -and $KeyName -in @('ClrRetrieverKind', 'EnableMultithreadedCompilation')
        }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -eq 'US compilation settings before change: ClrRetrieverKind=OneApplicationOneAssembly; EnableMultithreadedCompilation=false'
        }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -eq 'US compilation settings after restart: ClrRetrieverKind=OneApplicationMultipleAssemblies; EnableMultithreadedCompilation=true'
        }
    }

    It 'leaves other countries and missing country settings unchanged (<Country>)' -ForEach @(
        @{ Country = 'DK' }
        @{ Country = 'CA' }
        @{ Country = 'W1' }
        @{ Country = $null }
    ) {
        Mock Get-ALGoSetting { $Country }

        & $script:containerScript -parameters @{ ContainerName = 'test' }

        Should -Invoke Set-BcContainerServerConfiguration -Times 3 -Exactly
        Should -Invoke Get-NAVServerConfiguration -Times 0
        ($events -join ',') | Should -Be 'Restart,AppInfo,AppInfo'
    }

    It 'stops before app removal when <Key> does not take effect after restart' -ForEach @(
        @{ Key = 'ClrRetrieverKind' }
        @{ Key = 'EnableMultithreadedCompilation' }
    ) {
        Mock Restart-BcContainer {
            foreach ($writtenKey in $written.Keys) {
                if ($writtenKey -ne $Key) { $effective[$writtenKey] = $written[$writtenKey] }
            }
        }

        { & $script:containerScript -parameters @{ ContainerName = 'test' } } | Should -Throw '*mismatch after restart*'

        Should -Invoke Get-BcContainerAppInfo -Times 0
    }

    It 'fails explicitly when the server cannot return a supported effective setting' {
        Mock Get-NAVServerConfiguration { $null } -ParameterFilter { $KeyName -eq 'ClrRetrieverKind' }

        { & $script:containerScript -parameters @{ ContainerName = 'test' } } | Should -Throw '*Could not read*ClrRetrieverKind*'

        Should -Invoke Restart-BcContainer -Times 0
        Should -Invoke Get-BcContainerAppInfo -Times 0
    }

    It 'propagates setting errors instead of restarting or continuing publication' {
        Mock Set-BcContainerServerConfiguration { Write-Error 'setting write failed' } -ParameterFilter { $keyName -eq 'ClrRetrieverKind' }

        { & $script:containerScript -parameters @{ ContainerName = 'test' } } | Should -Throw '*setting write failed*'

        Should -Invoke Restart-BcContainer -Times 0
        Should -Invoke Get-BcContainerAppInfo -Times 0
    }
}
