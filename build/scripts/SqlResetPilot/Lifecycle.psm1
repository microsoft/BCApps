Set-StrictMode -Version 2
$script:pilot = $null

function Initialize-SqlResetPilot {
    param([string]$ContainerName, [array]$TenantInfo, [string]$Arm, [string]$RunId, [string]$OutputDirectory)
    if ($Arm -notin @('control', 'fresh') -or $RunId -notmatch '^\d{1,20}$') { throw 'Invalid pilot identity.' }
    if ($TenantInfo.Count -ne 4 -or @($TenantInfo.Id | Sort-Object -Unique).Count -ne 4) {
        throw 'Pilot requires exactly default and three distinct workers.'
    }
    $workers = @{}
    foreach ($id in @('tenant2', 'tenant3', 'tenant4')) {
        $info = @($TenantInfo | Where-Object Id -eq $id)
        if ($info.Count -ne 1 -or $info[0].DatabaseName -ne $id) { throw 'Unexpected initial owned worker mapping.' }
        $workers[$id] = @{ Info = $info[0]; Generation = 0; Owned = @($id); Used = @($id) }
    }
    $source = @($TenantInfo | Where-Object Id -eq 'default')
    if ($source.Count -ne 1 -or $source[0].DatabaseName -ne 'default') { throw 'Unexpected protected source mapping.' }
    $script:pilot = @{
        Container = $ContainerName; Arm = $Arm; RunId = $RunId; Workers = $workers
        OutputDirectory = $OutputDirectory
    }
}

function Get-SqlResetPlan {
    param([string]$ContainerName, [string]$Tenant, [string]$DatabaseName, [string]$TemplateDatabaseName)
    if (-not $script:pilot -or $ContainerName -ne $script:pilot.Container -or
        -not $script:pilot.Workers.ContainsKey($Tenant)) { throw 'Unowned container or tenant.' }
    $worker = $script:pilot.Workers[$Tenant]
    if ($DatabaseName -ne $worker.Info.DatabaseName -or $DatabaseName -notin $worker.Owned -or
        $TemplateDatabaseName -notin @('default', 'default-test-template') -or
        $DatabaseName -in @('default', 'default-test-template', 'app') -or
        $DatabaseName -eq $TemplateDatabaseName) { throw 'Unsafe or stale database mapping.' }
    $generation = $worker.Generation + 1
    $destination = if ($script:pilot.Arm -eq 'fresh') { "${Tenant}_r$($script:pilot.RunId)_g$generation" } else { $DatabaseName }
    if ($destination -notmatch '^tenant[234](?:_r\d{1,20}_g\d+)?$' -or $destination.Length -gt 64 -or
        ($script:pilot.Arm -eq 'fresh' -and $destination -in $worker.Used)) { throw 'Unsafe or reused destination.' }
    [PSCustomObject]@{
        Tenant = $Tenant; Previous = $DatabaseName; Destination = $destination
        Template = $TemplateDatabaseName; Generation = $generation
    }
}

function Complete-SqlResetPlan {
    param($Plan)
    $worker = $script:pilot.Workers[$Plan.Tenant]
    $worker.Info.DatabaseName = $Plan.Destination
    $worker.Generation = $Plan.Generation
    $worker.Owned = @($worker.Owned | Where-Object { $_ -ne $Plan.Previous }) + @($Plan.Destination)
    $worker.Used += $Plan.Destination
}

function Invoke-SqlPilotReset {
    param([string]$ContainerName, [string]$Tenant, [string]$DatabaseName, [string]$TemplateDatabaseName)
    $plan = Get-SqlResetPlan $ContainerName $Tenant $DatabaseName $TemplateDatabaseName
    $trace = Join-Path $script:pilot.OutputDirectory 'reset-timeline.jsonl'
    @{ phase = 'reset-start'; utc = [DateTime]::UtcNow.ToString('o'); arm = $script:pilot.Arm; plan = $plan } |
        ConvertTo-Json -Depth 5 -Compress | Add-Content $trace
    try {
        $result = Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -scriptblock {
            param($plan)
            $ErrorActionPreference = 'Stop'
            $stopwatch = [Diagnostics.Stopwatch]::StartNew()
            $mounted = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant
            $localServers = @('.', 'localhost', $env:COMPUTERNAME, '.\SQLEXPRESS', 'localhost\SQLEXPRESS', "$env:COMPUTERNAME\SQLEXPRESS")
            if ($mounted.DatabaseName -ne $plan.Previous -or $mounted.DatabaseServer -notin $localServers) {
                throw 'Actual mounted mapping differs from the owned local SQL mapping.'
            }
            if ($plan.Destination -ne $plan.Previous -and (Test-NAVDatabase -DatabaseName $plan.Destination)) {
                throw 'Fresh database destination already exists; refusing to overwrite it.'
            }
            function Read-PilotIdentity($name) {
                $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=.\SQLEXPRESS;Database=master;Integrated Security=True;TrustServerCertificate=True'
                try {
                    $connection.Open()
                    $command = $connection.CreateCommand()
                    $command.CommandText = 'SELECT name, database_id, create_date, service_broker_guid FROM sys.databases WHERE name = @name'
                    $null = $command.Parameters.AddWithValue('@name', $name)
                    $reader = $command.ExecuteReader()
                    if (-not $reader.Read()) { throw 'Owned SQL database identity is missing.' }
                    @{ name = [string]$reader[0]; databaseId = [int]$reader[1]; created = [string]$reader[2]; serviceBrokerGuid = [string]$reader[3] }
                } finally { $connection.Dispose() }
            }
            $before = Read-PilotIdentity $plan.Previous
            $started = [DateTime]::UtcNow.ToString('o')
            Dismount-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant -Force | Out-Null
            if (Test-NAVDatabase -DatabaseName $plan.Previous) {
                Remove-NAVDatabase -DatabaseName $plan.Previous | Out-Null
            }
            Copy-NAVDatabase -SourceDatabaseName $plan.Template -DestinationDatabaseName $plan.Destination -DatabaseServer '.' | Out-Null
            Mount-NAVTenant -ServerInstance $ServerInstance -Id $plan.Tenant -DatabaseServer '.' `
                -DatabaseName $plan.Destination -OverwriteTenantIdInDatabase -Force | Out-Null
            while ((Get-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant).State -eq 'Mounting') {
                if ($stopwatch.Elapsed.TotalSeconds -ge 300) { throw 'Tenant mount exceeded baseline 300-second bound.' }
                Start-Sleep -Milliseconds 250
            }
            $mounted = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant
            if ($mounted.State -notin @('Operational', 'OperationalWithWarnings') -or $mounted.DatabaseName -ne $plan.Destination) {
                throw 'Mounted state or mapping differs from the expected new generation.'
            }
            @{
                startedUtc = $started; completedUtc = [DateTime]::UtcNow.ToString('o')
                before = $before; after = (Read-PilotIdentity $plan.Destination)
                databaseServer = [string]$mounted.DatabaseServer; state = [string]$mounted.State
                detailedState = [string]$mounted.DetailedState; forceRefresh = $false
                nst = @(Get-Process 'Microsoft.Dynamics.Nav.Server' | ForEach-Object {
                    @{ pid = $_.Id; version = $_.FileVersion }
                })
            }
        } -argumentList $plan
        Complete-SqlResetPlan $plan
        @{ phase = 'reset-complete'; utc = [DateTime]::UtcNow.ToString('o'); plan = $plan; observation = $result } |
            ConvertTo-Json -Depth 8 -Compress | Add-Content $trace
    } catch {
        # Do not log exception text: SQL/provider diagnostics can contain connection information.
        @{ phase = 'reset-failed'; utc = [DateTime]::UtcNow.ToString('o'); plan = $plan; errorType = $_.Exception.GetType().FullName } |
            ConvertTo-Json -Depth 5 -Compress | Add-Content $trace
        throw
    }
}

function Select-SqlPilotPrefix {
    param([array]$WorkItems)
    $ids = @(139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343)
    if ($WorkItems.Count -lt $ids.Count) { throw 'Discovery returned an incomplete pilot prefix.' }
    for ($i = 0; $i -lt $ids.Count; $i++) {
        if ([int]$WorkItems[$i].CodeunitId -ne $ids[$i]) { throw "Pinned 21-codeunit discovery order differs at position $i; do not reorder or reduce the cohort." }
    }
    @($WorkItems | Select-Object -First $ids.Count)
}

<#
.SYNOPSIS
    Probes companies from the host after an owned worker restore, with bounded readiness retries.
.DESCRIPTION
    Uses the disposable container's existing password credential and private API endpoint.
    Only transient HTTP and connection/timeout failures may retry, up to three attempts.
    No redirects, response bodies, passwords or authorization headers are logged.
#>
function Invoke-SqlPilotCompaniesProbe {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingAllowUnencryptedAuthentication', '',
        Justification = 'Preserves the existing disposable-container Basic authentication over its private Docker address.')]
    [CmdletBinding()]
    param(
        [string]$ContainerName, [string]$Tenant,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [Parameter(Mandatory)][string]$CompanyName
    )
    if (-not $script:pilot -or $ContainerName -ne $script:pilot.Container -or
        -not $script:pilot.Workers.ContainsKey($Tenant) -or
        $script:pilot.Workers[$Tenant].Generation -lt 1) {
        throw 'Companies probe requires an owned, freshly restored worker.'
    }
    $maximumAttempts = if ($env:BC_SQL_API_EXPERIMENT -in @('A', 'B')) { 1 } else { 3 }
    $trace = Join-Path $script:pilot.OutputDirectory 'companies-probes.jsonl'
    $observation = @{
        tenant = $Tenant; generation = $script:pilot.Workers[$Tenant].Generation
        startedUtc = [DateTime]::UtcNow.ToString('o'); status = $null; passed = $false
        clientRequestId = [guid]::NewGuid().ToString(); serverRequestId = $null
        uri = $null; retries = 0; attempts = 0; recordType = 'outcome'
        outcome = 'failed'; recovered = $false; maximumAttempts = $maximumAttempts
    }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    try {
        # Match BCH's direct container API address, without its request wrapper or auth negotiation.
        $config = Get-BcContainerServerConfiguration -ContainerName $ContainerName
        $ip = Get-BcContainerIpAddress -containerName $ContainerName
        $parsedIp = $null
        if (-not [Net.IPAddress]::TryParse($ip, [ref]$parsedIp) -or
            $config.ServerInstance -notmatch '^[a-zA-Z0-9_-]+$' -or
            $config.ClientServicesCredentialType -notin @('NavUserPassword', 'UserPassword')) {
            throw 'Unexpected container API configuration.'
        }
        $scheme = if ($config.ODataServicesSSLEnabled -eq 'true') { 'https' } else { 'http' }
        $uri = [UriBuilder]::new($scheme, $ip, [int]$config.ODataServicesPort,
            "$($config.ServerInstance)/api/v2.0/companies", "?tenant=$Tenant").Uri.AbsoluteUri
        $observation.uri = $uri
        for ($attemptNumber = 1; $attemptNumber -le $maximumAttempts; $attemptNumber++) {
            $attempt = @{
                recordType = 'attempt'; probeId = $observation.clientRequestId
                tenant = $Tenant; generation = $observation.generation; uri = $uri
                attempt = $attemptNumber; startedUtc = [DateTime]::UtcNow.ToString('o')
                status = $null; passed = $false; retryable = $false
                clientRequestId = [guid]::NewGuid().ToString(); serverRequestId = $null
            }
            $attemptClock = [Diagnostics.Stopwatch]::StartNew()
            try {
                $response = Invoke-WebRequest -Uri $uri -Method Get -Authentication Basic -Credential $Credential `
                    -AllowUnencryptedAuthentication -SkipCertificateCheck -SkipHttpErrorCheck -MaximumRedirection 0 `
                    -MaximumRetryCount 0 -TimeoutSec 20 -OperationTimeoutSeconds 20 -ErrorAction Stop `
                    -Headers @{ Accept = 'application/json'; 'client-request-id' = $attempt.clientRequestId }
                $attempt.status = [int]$response.StatusCode
                foreach ($key in @('request-id', 'x-ms-request-id')) {
                    $value = [string]($response.Headers[$key] | Select-Object -First 1)
                    if ($value -match '^[a-zA-Z0-9._:-]{1,128}$') { $attempt.serverRequestId = $value; break }
                }
                if ($attempt.status -ne 200) {
                    $attempt.errorCategory = 'HttpStatus'
                    $attempt.retryable = $attempt.status -in @(500, 502, 503, 504)
                } else {
                    $body = $response.Content | ConvertFrom-Json -ErrorAction Stop
                    if (-not $body.PSObject.Properties['value'] -or
                        @($body.value | Where-Object { $_.name -eq $CompanyName -and $_.id }).Count -ne 1) {
                        throw 'Companies probe did not return exactly one expected company.'
                    }
                    $attempt.passed = $true
                }
            } catch {
                $attempt.errorType = $_.Exception.GetType().FullName
                $attempt.errorCategory = 'PermanentFailure'
                # Inspect types, never exception messages (which may contain authentication material).
                if ($null -eq $attempt.status) {
                    $exception = $_.Exception
                    while ($null -ne $exception) {
                        if ($exception -is [TimeoutException] -or
                            $exception -is [OperationCanceledException] -or
                            ($exception -is [Net.Http.HttpRequestException] -and
                                $exception.PSObject.Properties['HttpRequestError'] -and
                                $exception.HttpRequestError -in @('ConnectionError', 'NameResolutionError', 'ResponseEnded')) -or
                            ($exception -is [Net.Sockets.SocketException] -and
                                $exception.SocketErrorCode -in @('ConnectionRefused', 'ConnectionReset', 'ConnectionAborted',
                                    'HostNotFound', 'HostUnreachable', 'NetworkDown', 'NetworkReset', 'NetworkUnreachable', 'TimedOut', 'TryAgain')) -or
                            ($exception -is [Net.WebException] -and
                                $exception.Status -in @('Timeout', 'ConnectFailure', 'ConnectionClosed', 'KeepAliveFailure',
                                    'ReceiveFailure', 'SendFailure', 'NameResolutionFailure', 'ProxyNameResolutionFailure'))) {
                            $attempt.retryable = $true
                            $attempt.errorCategory = 'ConnectionOrTimeout'
                            break
                        }
                        $exception = $exception.InnerException
                    }
                }
            } finally {
                $attempt.completedUtc = [DateTime]::UtcNow.ToString('o')
                $attempt.elapsedMilliseconds = $attemptClock.ElapsedMilliseconds
                $attempt | ConvertTo-Json -Compress | Add-Content $trace
                $observation.attempts = $attemptNumber
                $observation.retries = $attemptNumber - 1
                $observation.status = $attempt.status
                $observation.serverRequestId = $attempt.serverRequestId
            }
            if ($attempt.passed) {
                $observation.passed = $true
                $observation.recovered = $attemptNumber -gt 1
                $observation.outcome = if ($observation.recovered) { 'recovered' } else { 'first-try-success' }
                break
            }
            if (-not $attempt.retryable -or $attemptNumber -eq $maximumAttempts) { break }
            Start-Sleep -Seconds 2
        }
        if (-not $observation.passed) { throw 'Companies probe exhausted eligible attempts or encountered a permanent failure.' }
    } catch {
        $observation.errorType = $_.Exception.GetType().FullName
        # HTTP exception details can contain authentication material; never emit the original error.
        throw "Companies probe failed for $Tenant after $($observation.attempts) attempt(s); see sanitized companies-probes.jsonl."
    } finally {
        $observation.completedUtc = [DateTime]::UtcNow.ToString('o')
        $observation.elapsedMilliseconds = $clock.ElapsedMilliseconds
        $observation | ConvertTo-Json -Compress | Add-Content $trace
    }
}

Export-ModuleMember -Function Initialize-SqlResetPilot, Get-SqlResetPlan, Complete-SqlResetPlan, Invoke-SqlPilotReset, Select-SqlPilotPrefix, Invoke-SqlPilotCompaniesProbe
