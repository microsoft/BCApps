function Get-SqlTenantResourceSample {
    param([string]$ContainerName, [string]$Phase)
    $sample = @{ utc = [DateTime]::UtcNow.ToString('o'); ticks = [Diagnostics.Stopwatch]::GetTimestamp()
        phase = $Phase; errors = @(); host = $null; container = $null }
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cpus = @(Get-CimInstance Win32_Processor -ErrorAction Stop)
        $sample.host = @{
            logicalProcessors = ($cpus | Measure-Object NumberOfLogicalProcessors -Sum).Sum
            cpuLoadPercent = ($cpus | Measure-Object LoadPercentage -Average).Average
            totalMemoryKB = $os.TotalVisibleMemorySize; freeMemoryKB = $os.FreePhysicalMemory
            totalVirtualKB = $os.TotalVirtualMemorySize; freeVirtualKB = $os.FreeVirtualMemory
        }
        try {
            $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction Stop
            $sample.host.pagesPerSecond = $memory.PagesPersec
            $sample.host.pageReadsPerSecond = $memory.PageReadsPersec
            $sample.host.pageWritesPerSecond = $memory.PageWritesPersec
        } catch { $sample.errors += "host-paging:$($_.Exception.GetType().FullName)" }
    } catch { $sample.errors += "host:$($_.Exception.GetType().FullName)" }
    if ($ContainerName) {
        try {
            $sample.container = Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -scriptblock {
                $data = @{ processes = @(); sqlWaits = @(); sqlIO = @(); errors = @() }
                foreach ($name in @('Microsoft.Dynamics.Nav.Server', 'sqlservr')) {
                    try {
                        $data.processes += @(Get-Process -Name $name -ErrorAction Stop | ForEach-Object {
                            @{ name = $_.ProcessName; pid = $_.Id; cpuSeconds = $_.CPU
                                workingSetBytes = $_.WorkingSet64; privateBytes = $_.PrivateMemorySize64
                                threads = $_.Threads.Count; handles = $_.HandleCount }
                        })
                    } catch { $data.errors += "process:$name`:$($_.Exception.GetType().FullName)" }
                }
                $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=.\SQLEXPRESS;Database=master;Integrated Security=True;TrustServerCertificate=True;Connection Timeout=5'
                try {
                    $connection.Open()
                    $queries = @{
                        sqlWaits = 'SELECT TOP (12) wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms FROM sys.dm_os_wait_stats ORDER BY wait_time_ms DESC'
                        sqlIO = 'SELECT database_id, SUM(num_of_reads) AS reads, SUM(num_of_bytes_read) AS bytes_read, SUM(io_stall_read_ms) AS read_stall_ms, SUM(num_of_writes) AS writes, SUM(num_of_bytes_written) AS bytes_written, SUM(io_stall_write_ms) AS write_stall_ms FROM sys.dm_io_virtual_file_stats(NULL,NULL) GROUP BY database_id'
                    }
                    foreach ($key in $queries.Keys) {
                        $command = $connection.CreateCommand()
                        $command.CommandText = $queries[$key]
                        $command.CommandTimeout = 5
                        $reader = $command.ExecuteReader()
                        try {
                            while ($reader.Read()) {
                                $row = @{}
                                for ($i = 0; $i -lt $reader.FieldCount; $i++) { $row[$reader.GetName($i)] = $reader.GetValue($i) }
                                $data[$key] += $row
                            }
                        } finally { $reader.Close() }
                    }
                } catch { $data.errors += "sql-observation:$($_.Exception.GetType().FullName)" }
                finally { $connection.Dispose() }
                $data
            }
        } catch { $sample.errors += "container:$($_.Exception.GetType().FullName)" }
    }
    [PSCustomObject]$sample
}

function Start-SqlTenantSampler {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal read-only sampler for an explicitly owned disposable diagnostic container.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseUsingScopeModifierInNewRunspaces', '',
        Justification = 'All job arguments are passed explicitly through ArgumentList and declared in param.')]
    [CmdletBinding()]
    param([string]$ContainerName, [string]$Directory)
    $bch = Get-Module BcContainerHelper -ErrorAction Stop | Select-Object -First 1
    if (-not $bch.Path) { throw 'Sampler requires the already loaded pinned helper.' }
    $path = Join-Path $Directory 'resource-samples.jsonl'
    Get-SqlTenantResourceSample -ContainerName $ContainerName -Phase 'execution-start' |
        ConvertTo-Json -Depth 10 -Compress | Add-Content $path
    Start-Job -ScriptBlock {
        param($modulePath, $helperPath, $container, $output)
        $ErrorActionPreference = 'Stop'
        Import-Module $helperPath
        Import-Module $modulePath
        while ($true) {
            Start-Sleep -Seconds 30
            Get-SqlTenantResourceSample -ContainerName $container -Phase 'execution-periodic' |
                ConvertTo-Json -Depth 10 -Compress | Add-Content $output
        }
    } -ArgumentList $PSCommandPath, $bch.Path, $ContainerName, $path
}

function Stop-SqlTenantSampler {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Mandatory finally cleanup of only the explicit sampler Job instance.')]
    [CmdletBinding()]
    param($Job, [string]$ContainerName, [string]$Directory)
    $status = @{ stopped = $false; samplerError = $null; measurementComplete = $false }
    try {
        if ($Job) {
            if ($Job.State -eq 'Failed') { $status.samplerError = 'Background sampler failed; see received error record.' }
            try {
                Stop-Job -Job $Job -ErrorAction Stop
                $status.stopped = $true
                Receive-Job -Job $Job -ErrorAction Stop | Out-Null
            } finally { Remove-Job -Job $Job -Force -ErrorAction Stop }
        } else { $status.samplerError = 'Sampler never started.' }
    } catch { $status.samplerError = $_.Exception.GetType().FullName }
    $path = Join-Path $Directory 'resource-samples.jsonl'
    Get-SqlTenantResourceSample -ContainerName $ContainerName -Phase 'execution-end' |
        ConvertTo-Json -Depth 10 -Compress | Add-Content $path
    $samples = @(Get-Content $path | ForEach-Object { $_ | ConvertFrom-Json })
    $valid = @($samples | Where-Object {
        $_.host -and $_.container -and @($_.container.processes).Count -ge 2 -and
        @($_.errors).Count -eq 0 -and @($_.container.errors).Count -eq 0
    })
    $status.sampleCount = $samples.Count
    $status.fullyObservedSamples = $valid.Count
    $status.measurementComplete = $valid.Count -eq $samples.Count -and -not $status.samplerError
    $status.note = 'Cumulative process CPU and SQL counters require deltas; per-database I/O resets when a worker database is replaced. Host samples include other host activity.'
    $status | ConvertTo-Json | Set-Content (Join-Path $Directory 'resource-status.json')
}

Export-ModuleMember -Function Get-SqlTenantResourceSample, Start-SqlTenantSampler, Stop-SqlTenantSampler
