Import-Module (Join-Path $PSScriptRoot 'TenantResources.psm1') -Force
BeforeAll {
    function global:Invoke-ScriptInBcContainer {param($containerName,$useSession,$scriptblock,$argumentList) throw 'Live call forbidden.'}
}
Describe 'Resource instrumentation fails visibly and cleans up' {
    BeforeEach { Remove-Item (Join-Path $TestDrive 'resource-samples.jsonl') -ErrorAction SilentlyContinue }
    InModuleScope TenantResources {
        It 'preserves host and container measurement failures explicitly' {
            Mock Get-CimInstance {throw 'denied'}
            Mock Invoke-ScriptInBcContainer {throw 'unavailable'}
            $sample=Get-SqlTenantResourceSample owned execution
            $sample.host | Should -BeNullOrEmpty
            $sample.container | Should -BeNullOrEmpty
            $sample.errors.Count | Should -Be 2
        }
        It 'reports observed host CPU memory and owned process sample' {
            Mock Get-CimInstance {
                switch($ClassName) {
                    Win32_OperatingSystem {@{TotalVisibleMemorySize=16000;FreePhysicalMemory=8000;TotalVirtualMemorySize=32000;FreeVirtualMemory=24000}}
                    Win32_Processor {@{NumberOfLogicalProcessors=4;LoadPercentage=30}}
                    Win32_PerfFormattedData_PerfOS_Memory {@{PagesPersec=1;PageReadsPersec=0;PageWritesPersec=1}}
                }
            }
            Mock Invoke-ScriptInBcContainer {@{processes=@(@{name='nst';cpuSeconds=1;workingSetBytes=100},@{name='sql';cpuSeconds=2;workingSetBytes=200});errors=@()}}
            $sample=Get-SqlTenantResourceSample owned execution
            $sample.errors.Count | Should -Be 0
            $sample.host.cpuLoadPercent | Should -Be 30
            $sample.host.freeMemoryKB | Should -Be 8000
            $sample.container.processes.Count | Should -Be 2
        }
        It 'starts one bounded periodic job using the already loaded helper' {
            Mock Get-Module {[PSCustomObject]@{Path='pinned-helper.psm1'}}
            Mock Get-SqlTenantResourceSample {@{host=@{};container=@{};errors=@()}}
            Mock Start-Job {[PSCustomObject]@{Id=7}}
            $job=Start-SqlTenantSampler owned $TestDrive
            $job.Id | Should -Be 7
            Should -Invoke Start-Job -Times 1 -Exactly -ParameterFilter {
                $ArgumentList[0] -like '*TenantResources.psm1' -and $ArgumentList[1] -eq 'pinned-helper.psm1' -and
                $ScriptBlock.ToString() -match 'Start-Sleep -Seconds 30'
            }
        }
        It 'stops only its explicit job and reports incomplete samples' {
            Mock Stop-Job {}
            Mock Receive-Job {}
            Mock Remove-Job {}
            Mock Get-SqlTenantResourceSample {@{host=$null;container=$null;errors=@('unavailable')}}
            $job=Microsoft.PowerShell.Core\Start-Job { 1 }
            Microsoft.PowerShell.Core\Wait-Job $job | Out-Null
            try {
                Stop-SqlTenantSampler $job owned $TestDrive
                Should -Invoke Stop-Job -Times 1 -Exactly
                Should -Invoke Remove-Job -Times 1 -Exactly
            } finally {
                Microsoft.PowerShell.Core\Remove-Job $job -Force
            }
            $status=Get-Content (Join-Path $TestDrive 'resource-status.json') -Raw | ConvertFrom-Json
            $status.stopped | Should -BeTrue
            $status.measurementComplete | Should -BeFalse
            $status.sampleCount | Should -Be 1
        }
    }
}
